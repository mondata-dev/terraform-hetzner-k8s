#!/bin/bash
set -eu

# from https://community.hetzner.com/tutorials/install-kubernetes-cluster#step-21---configure-floating-ips
mkdir -p /etc/network/interfaces.d
echo "auto eth0:1"              >> /etc/network/interfaces.d/60-floating-ip.cfg
echo "iface eth0:1 inet static" >> /etc/network/interfaces.d/60-floating-ip.cfg
echo "  address $1"             >> /etc/network/interfaces.d/60-floating-ip.cfg
echo "  netmask 32"             >> /etc/network/interfaces.d/60-floating-ip.cfg

systemctl restart networking.service
