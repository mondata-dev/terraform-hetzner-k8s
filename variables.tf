variable "hcloud_token" {
  type = string
}

variable "ssh_key_name" {
  description = "If not an empty string, terraform will create an ssh key with that name. See also ssh_public_key_file"
  type = string
  default = ""
}

variable "ssh_public_key_file" {
  description = "The file to read the ssh public key from. Will only be used if ssh_key_name is not empty"
  type = string
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_file" {
  description = "The file to read the ssh private key from when connecting to the new server for provisioning."
  type = string
  default = "~/.ssh/id_rsa"
}

variable "worker_cnt" {
  type = number
  default = 2
}
