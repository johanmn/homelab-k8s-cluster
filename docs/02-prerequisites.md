# Phase 2: Kubernetes Prerequisites Setup Guide

Follow these steps on **ALL 3 Raspberry Pi nodes** (`control-plane`, `worker-1`, `worker-2`).

## 1. Disable Swap (Critical & Persistent)
Kubernetes requires swap to be disabled. On modern Debian/Raspberry Pi OS, the most reliable way to kill it is via systemd masking.

Run these commands:

```bash
# 1. Turn off swap immediately
sudo swapoff -a

# 2. Prevent systemd from ever starting swap again (The Nuclear Option)
sudo systemctl mask swap.target

# 3. Comment out swap in /etc/fstab to stop boot errors
# This command adds a # to the start of any line with "swap" in it
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 4. Verify swap is gone (Should show 0B)
free -h
```

## 2. Load Kernel Modules
We need `overlay` (for containerd) and `br_netfilter` (for networking).

1.  **Create config file**:
    ```bash
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF
    ```
2.  **Load modules immediately**:
    ```bash
    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```
3.  **Verify**:
    ```bash
    lsmod | grep br_netfilter
    lsmod | grep overlay
    ```

## 3. Configure Networking Parameters (Sysctl)
Allow iptables to see bridged traffic.

1.  **Create config file**:
    ```bash
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF
    ```
2.  **Apply settings**:
    ```bash
    sudo sysctl --system
    ```

## 4. Install Container Runtime (Containerd)
We will install `containerd` from Docker's official repo.

1.  **Set up Docker's apt repository**:
    ```bash
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    ```
2.  **Install containerd**:
    ```bash
    sudo apt-get install -y containerd.io
    ```

## 5. Configure Containerd (Important for K8s)
By default, containerd is not configured for Kubernetes (needs SystemdCgroup).

1.  **Generate default config**:
    ```bash
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    ```
2.  **Edit config to enable SystemdCgroup**:
    *   Open the file: `sudo nano /etc/containerd/config.toml`
    *   Find the section `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]`
    *   Change `SystemdCgroup = false` to `SystemdCgroup = true`
    *   (Or use this sed command):
        ```bash
        sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        ```
3.  **Restart containerd**:
    ```bash
    sudo systemctl restart containerd
    ```

## 6. Install Kubeadm, Kubelet, and Kubectl
We will install version **1.32** (Stable).
> **Note**: v1.32 uses modern signing keys compatible with Debian Trixie (2026) security policies.

1.  **Install dependencies**:
    ```bash
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg
    ```
2.  **Download the public signing key (v1.32)**:
    ```bash
    # If the directory config doesn't exist create it
    sudo mkdir -p -m 755 /etc/apt/keyrings
    # Remove old key if present to avoid conflicts
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    ```
3.  **Add the Kubernetes apt repository**:
    ```bash
    # Remove old list if present
    sudo rm -f /etc/apt/sources.list.d/kubernetes.list
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    ```
4.  **Update apt package index**:
    ```bash
    sudo apt-get update
    ```
5.  **Install kubelet, kubeadm and kubectl**:
    ```bash
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```
