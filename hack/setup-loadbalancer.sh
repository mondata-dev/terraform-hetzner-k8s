#!/bin/bash
set -eu

# TODO remove this in environments with only helm3 installed as helm
HELM=helm3

# Setup MetalLB
# See https://community.hetzner.com/tutorials/install-kubernetes-cluster#step-35---setup-loadbalancing-optional
$HELM repo add bitnami https://charts.bitnami.com/bitnami
$HELM repo update

kubectl create namespace metallb
$HELM install metallb bitnami/metallb --namespace metallb \
  --set configInline.address-pools[0].name=default \
  --set configInline.address-pools[0].protocol=layer2 \
  --set configInline.address-pools[0].addresses[0]=$HCLOUD_FLOATING_IP/32

# Setup IP Failover
# See https://community.hetzner.com/tutorials/install-kubernetes-cluster#step-36---setup-floating-ip-failover-optional
$HELM repo add cbeneke https://cbeneke.github.io/helm-charts
$HELM repo update

kubectl create namespace fip-controller
$HELM install hcloud-fip-controller cbeneke/hcloud-fip-controller --namespace fip-controller

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: hcloud-fip-controller-config
  namespace: fip-controller
data:
  config.json: |
    {
      "hcloud_floating_ips": [
        "$HCLOUD_FLOATING_IP"
      ],
      "node_address_type": "external"
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: hcloud-fip-controller-env
  namespace: fip-controller
stringData:
  HCLOUD_API_TOKEN: $HCLOUD_TOKEN
EOF
