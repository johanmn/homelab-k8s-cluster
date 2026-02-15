#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}[*] Setting up Kubernetes Prerequisites...${NC}"

# 1. Disable swap (Robust method)
echo -e "${GREEN}[*] Disabling swap...${NC}"
sudo swapoff -a
sudo systemctl mask swap.target
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
if command -v dphys-swapfile &> /dev/null; then
    sudo dphys-swapfile swapoff
    sudo systemctl disable dphys-swapfile
    sudo apt-get purge -y dphys-swapfile
fi

# 2. Update and Install prerequisites
echo -e "${GREEN}[*] Installing prerequisites...${NC}"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# 3. Enable Kernel Modules
echo -e "${GREEN}[*] Enabling kernel modules...${NC}"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 4. Configure Sysctl
echo -e "${GREEN}[*] Configuring sysctl params...${NC}"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 5. Install Containerd
echo -e "${GREEN}[*] Installing Containerd...${NC}"
# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io

# 6. Configure Containerd
echo -e "${GREEN}[*] Configuring Containerd (SystemdCgroup = true)...${NC}"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# 7. Check Cgroups in cmdline.txt (for RPi specifically)
# Just a verification, adding if missing is safer done with sed carefully or manually
if ! grep -q "cgroup_memory=1" /boot/firmware/cmdline.txt && ! grep -q "cgroup_memory=1" /boot/cmdline.txt; then
    echo -e "${RED}[!] WARNING: cgroup_memory=1 not found in /boot/cmdline.txt or /boot/firmware/cmdline.txt${NC}"
    echo -e "${RED}[!] MAKE SURE YOU ADDED: cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1${NC}"
fi

# 8. Install Kubernetes Components
echo -e "${GREEN}[*] Installing Kubeadm, Kubelet, Kubectl (v1.32)...${NC}"
# Using pkgs.k8s.io
# Cleaning old keys/lists just in case
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo -e "${GREEN}[*] Node setup complete! Ready for kubeadm init/join.${NC}"
