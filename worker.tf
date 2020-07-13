resource "hcloud_server" "worker" {
  name = "worker-${count.index}"
  image = "ubuntu-18.04"
  server_type = "cx21"
  location = "nbg1"
  ssh_keys = local.ssh_keys

  count = var.worker_cnt
}

resource "hcloud_server_network" "worker" {
  server_id = hcloud_server.worker[count.index].id
  network_id = hcloud_network.vb_cdap_k8s.id

  count = var.worker_cnt
}

resource "null_resource" "worker_provisioners" {
  count = var.worker_cnt

  depends_on = [
    null_resource.master_provisioners,
    hcloud_floating_ip.vb_cdap_load_balancer,
    hcloud_server_network.worker,
  ]

  connection {
    type = "ssh"
    user = "root"
    host = hcloud_server.worker[count.index].ipv4_address
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
}
