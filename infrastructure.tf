# terraform {
#   backend "gcs" {
#     credentials = "../gcp-project-12345-02829d1c4a5a_terraform-sp-key.json"
#     bucket  = "vb-terraform-state"
#     prefix  = "vb-cdab/tfstate"
#   }
# }

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
  version = "~> 1.19"
}

# Setup ssh keys
data "hcloud_ssh_keys" "admin_keys" {
  with_selector = "group=admin"
}

resource "hcloud_ssh_key" "cur_user" {
  name = var.ssh_key_name
  public_key = file(var.ssh_public_key_file)

  count = var.ssh_key_name != "" ? 1 : 0
}

locals {
  ssh_keys = concat(data.hcloud_ssh_keys.admin_keys.ssh_keys.*.name, hcloud_ssh_key.cur_user.*.name)
}

# Setup network
resource "hcloud_network" "vb_cdap_k8s" {
  name = "vb-cdap-k8s"
  ip_range = "10.98.0.0/16"
}

resource "hcloud_network_subnet" "vb_cdap_k8s" {
  network_id = hcloud_network.vb_cdap_k8s.id
  type = "server"
  network_zone = "eu-central"
  ip_range   = "10.98.0.0/16"
}

# Setup Public IP for load balancer service
resource "hcloud_floating_ip" "vb_cdap_load_balancer" {
  type = "ipv4"
  home_location = "nbg1"
}

# Setup nodes
resource "hcloud_server" "master" {
  name = "master-1"
  image = "ubuntu-18.04"
  server_type = "cx11"
  location = "nbg1"
  ssh_keys = local.ssh_keys

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "file" {
    source = "${path.module}/hack/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "file" {
    source = "${path.module}/hack/master.sh"
    destination = "/root/master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash /root/bootstrap.sh",
      "/bin/bash /root/master.sh ${var.hcloud_token} ${hcloud_network.vb_cdap_k8s.id}",
    ]
  }

  provisioner "local-exec" {
	  command = "bash ${path.module}/hack/copy_local.sh"

		environment = {
			SSH_PRIVATE_KEY 	= var.ssh_private_key_file
			SSH_CONN   				= "root@${hcloud_server.master.ipv4_address}"
			COPY_TO_LOCAL    	= "creds/"
		}
	}
}

resource "hcloud_server_network" "master" {
  server_id = hcloud_server.master.id
  network_id = hcloud_network.vb_cdap_k8s.id
}

resource "hcloud_server" "worker" {
  name = "worker-${count.index}"
  image = "ubuntu-18.04"
  server_type = "cx21"
  location = "nbg1"
  ssh_keys = local.ssh_keys

  depends_on = [
    hcloud_floating_ip.vb_cdap_load_balancer,
    hcloud_server.master
  ]

  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "file" {
    source = "${path.module}/hack/setup-floating-ip.sh"
    destination = "/root/setup-floating-ip.sh"
  }

  provisioner "file" {
    source = "${path.module}/hack/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "file" {
    source      = "${path.module}/creds/cluster_join"
    destination = "/tmp/cluster_join"
  }

  provisioner "file" {
    source      = "${path.module}/hack/worker.sh"
    destination = "/root/worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash /root/setup-floating-ip.sh ${hcloud_floating_ip.vb_cdap_load_balancer.ip_address}",
      "/bin/bash /root/bootstrap.sh",
      "/bin/bash /root/worker.sh",
    ]
  }

  count = var.worker_cnt
}

resource "hcloud_server_network" "worker" {
  server_id = hcloud_server.worker[count.index].id
  network_id = hcloud_network.vb_cdap_k8s.id

  count = var.worker_cnt
}
