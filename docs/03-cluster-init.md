# Phase 3: Cluster Initialization Guide

Follow these steps to bootstrap your Kubernetes Control Plane and join your worker nodes.

## 1. Initialize Control Plane (Master Node Only)
Run this command **ONLY on `control-plane`** (192.168.100.50):

```bash
# Initialize the cluster with a specific pod network CIDR (required for Flannel)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

**What to expect:**
*   This may take a few minutes.
*   Once finished, it will output: `Your Kubernetes control-plane has initialized successfully!`
*   **COPY THE "JOIN COMMAND"** shown at the end of the output. It looks like:
    `sudo kubeadm join 192.168.100.50:6443 --token ... --discovery-token-ca-cert-hash ...`

## 2. Configure Kubectl (Master Node Only)
To run `kubectl` commands as your regular user (`pi`), run these 3 commands on the **Master**:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Verify:**
```bash
kubectl get nodes
```
*   You should see `control-plane`. Status might be `NotReady` (this is normal because we haven't installed the network yet).

## 3. Install Pod Network (CNI) - Flannel
Run this on the **Master** node to install the network driver:

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

**Verify:**
Wait about 1-2 minutes, then run:
```bash
kubectl get nodes
```
*   The `control-plane` status should change to `Ready`.

## 4. Join Worker Nodes
Run the **OFFICIAL JOIN COMMAND** (that you copied in step 1) on both **Worker 1** (`192.168.100.53`) and **Worker 2** (`192.168.100.55`).

```bash
# Example (DO NOT COPY THIS - USE YOUR ACTUAL TOKEN):
sudo kubeadm join 192.168.100.50:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:0123...
```
*(If you lost the token, run `kubeadm token create --print-join-command` on the Master to get it again.)*

## 5. Final Verification
Back on the **Master** node, check your cluster:

```bash
kubectl get nodes -o wide
```

You should see:
*   3 Nodes (`control-plane`, `worker-1`, `worker-2`)
*   Status: **Ready** for all of them.
*   Roles: `control-plane` for master, `<none>` for workers.
