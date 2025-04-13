#!/bin/bash
set -e

source ./check-root.sh

# Conditional Kubernetes cleanup
if command -v kubeadm &>/dev/null || [ -d "/etc/kubernetes" ]; then
  echo "Cleaning up K8..."
  kubeadm reset -f || true
  systemctl stop kubelet || true
  systemctl disable kubelet || true
  apt-mark unhold kubeadm kubectl kubelet || true
  apt-get remove --purge -y kubeadm kubectl kubelet kubernetes-cni cri-tools || true
  apt-get autoremove -y || true
else
  echo "No existing instances of K8 to be cleaned up..."
fi

rm -rf /etc/kubernetes ~/.kube /var/lib/etcd /var/lib/kubelet /etc/cni/net.d /opt/cni/bin
rm -f /etc/apt/keyrings/kubernetes-archive-keyring.gpg
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
rm -f /etc/apt/sources.list.d/kubernetes.list
rm -rf $HOME/.kube

# Conditional Docker cleanup
if command -v docker &>/dev/null || systemctl list-unit-files | grep -q docker.service; then
  echo "Cleaning up Docker..."
  systemctl stop docker || true
  systemctl disable docker || true
  apt-get remove --purge -y docker-ce docker-ce-cli containerd.io || true
  apt-get autoremove -y || true
else
  echo "No existing instances of Docker to be cleaned up..."
fi

rm -rf /var/lib/docker /etc/docker
rm -f /etc/apt/keyrings/docker.gpg
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/trusted.gpg.d/docker.gpg

# Conditional containerd cleanup
if command -v containerd &>/dev/null || systemctl list-unit-files | grep -q containerd.service; then
  echo "Cleaning up containerd..."
  systemctl stop containerd || true
  systemctl disable containerd || true
  apt-get remove --purge -y containerd containerd.io || true
  apt-get autoremove -y || true
else
  echo "No existing instances of containerd to be cleaned up..."
fi

rm -rf /etc/containerd /var/lib/containerd /usr/local/bin/containerd*
rm -f /etc/systemd/system/containerd.service
