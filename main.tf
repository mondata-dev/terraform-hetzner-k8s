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

resource "null_resource" "provision_loadbalancers" {
  depends_on = [
    null_resource.master_provisioners,
    null_resource.worker_provisioners,
  ]

  provisioner "local-exec" {
    command = "bash ${path.module}/hack/setup-loadbalancer.sh"

    environment = {
      KUBECONFIG         = var.kubeconfig_path
      HCLOUD_FLOATING_IP = hcloud_floating_ip.vb_cdap_load_balancer.ip_address
      HCLOUD_TOKEN       = var.hcloud_token
    }
  }
}
