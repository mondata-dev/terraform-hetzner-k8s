resource "hcloud_server" "master" {
  name = "master-1"
  image = "ubuntu-18.04"
  server_type = "cx11"
  location = "nbg1"
  ssh_keys = local.ssh_keys
}

resource "hcloud_server_network" "master" {
  server_id = hcloud_server.master.id
  network_id = hcloud_network.vb_cdap_k8s.id
}

resource "null_resource" "master_provisioners" {
  depends_on = [hcloud_server_network.master]

  connection {
    type = "ssh"
    user = "root"
    host = hcloud_server.master.ipv4_address
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
    command = "bash ${path.module}/hack/copy-local.sh"

    environment = {
      SSH_PRIVATE_KEY   = var.ssh_private_key_file
      SSH_CONN          = "root@${hcloud_server.master.ipv4_address}"
      KUBECONFIG_PATH   = var.kubeconfig_path
    }
  }
}
