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

provider "null" {
  version = "~> 2.1"
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
