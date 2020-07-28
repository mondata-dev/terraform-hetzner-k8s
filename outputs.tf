output "kubeconfig_path" {
  description = "The path to the kubeconfig file for the newly created cluster"
  value = "${local.credentials_dir}/admin.conf"
}
