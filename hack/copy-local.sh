#!/bin/bash
#
# Via https://github.com/cbrgm/terraform-k8s-hetzner/blob/master/hack/copy_local.sh
#

set -eu

# Set values from env vars
SSH_PRIVATE_KEY=${SSH_PRIVATE_KEY:-}
SSH_CONN=${SSH_CONN:-}
KUBECONFIG_PATH=${KUBECONFIG_PATH:-}

# Create directory (+parents if not exists)
mkdir -p `dirname "${KUBECONFIG_PATH}"`

# Copy admin config
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "${SSH_PRIVATE_KEY}" \
    "${SSH_CONN}:/etc/kubernetes/admin.conf" \
    "${KUBECONFIG_PATH}"
