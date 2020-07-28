variable "hcloud_token" {
  type = string
}

provider "hcloud" {
  token = var.hcloud_token
  version = "~> 1.19"
}

provider "null" {
  version = "~> 2.1"
}

module "cluster" {
  source = "github.com/mondata-dev/terraform-hetzner-k8s?ref=master"

  hcloud_token = var.hcloud_token
  worker_cnt = 3
}
