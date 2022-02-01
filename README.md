# terraform-hetzner-k8s

A terraform module for a kubernetes cluster on hetzner cloud.

## Usage

For an example see `examples/basic/main.tf`.
Install with `terraform apply`.

After installation, fix hetzner security issues leading to abuse emails by installing the `disable-rpc-bind` daemon set:

```bash
kubectl apply -f examples/basic/disable-rpc-bind.yaml`
```

## Configuration

### SSH-Keys

By default, all nodes will be configured for ssh key access for admin keys.
Admin keys are all keys that are tagged `group=admin` in the hetzner cloud.
Alternatively, you can set the variable `ssh_key_name`.
