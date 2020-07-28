# terraform-hetzner-k8s

A terraform module for a kubernetes cluster on hetzner cloud.

## Configuration

### SSH-Keys

By default, all nodes will be configured for ssh key access for admin keys.
Admin keys are all keys that are tagged `group=admin` in the hetzner cloud.
Alternatively, you can set the variable `ssh_key_name`.
