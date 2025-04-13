#!/bin/bash
set -e

source ./check-root.sh
source ./k8s-cleanup.sh

DEFAULT_K8S_VERSION="v1.28"
K8S_VERSION=${1:-$DEFAULT_K8S_VERSION}

echo "Kubernetes version selection : $K8S_VERSION"

apt update

# Reset and reload iptables
apt install -y iptables iptables-persistent

# Restore Default iptables Rules
echo "Resetting IPTABLES..."
FILE="iptables-default.rules"
echo "*filter" > $FILE
echo ":INPUT ACCEPT [0:0]" >> $FILE
echo ":FORWARD ACCEPT [0:0]" >> $FILE
echo ":OUTPUT ACCEPT [0:0]" >> $FILE
echo "COMMIT" >> $FILE

iptables-restore < iptables-default.rules
iptables -A INPUT -p tcp --dport 6443 -j ACCEPT
netfilter-persistent save
netfilter-persistent reload

# Disable swap
echo "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "Swap disabled successfully."

# Load necessary modules
echo "Loading required kernel modules..."
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
echo "Kernel modules loaded successfully."

# Configure sysctl settings
echo "Configuring sysctl settings for Kubernetes..."
tee /etc/sysctl.d/kubernetes.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT

echo "net.ipv4.ip_forward=1" | tee /etc/sysctl.d/99-ipforward.conf
sysctl --system
echo "Sysctl settings configured successfully."

# Install Containerd Runtime Dependencies
apt install -y curl gpg gnupg2 software-properties-common apt-transport-https ca-certificates

# Add docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt update

# Install containerd
apt install -y containerd.io

# Configure Containerd to use systemd as cgroup
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# Restart and enable containerd
systemctl restart containerd
systemctl enable containerd

# Add K8s Repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt update

# Install K8s - kubelet, kubeadm & kubectl
echo "Installing K8s - $K8S_VERSION..."
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "Checking kubectl, kubelet and kubectl installations..."
dpkg -l | grep kube
which kubeadm kubectl kubelet kubectl
echo "Kubernetes components have been installed..."
