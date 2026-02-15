# Operations Guide: Cluster Shutdown & Startup

Gracefully shutting down your Raspberry Pi Kubernetes cluster is important to prevent database corruption (especially with Longhorn) and filesystem errors on SD cards.

## 1. Graceful Shutdown Procedure

### Step 1: Drain Worker Nodes (Optional but Recommended)
This safely evicts pods from worker nodes. Run this on your **Master Node** or Mac:

```bash
# Prevent new pods from scheduling
kubectl cordon worker-1 worker-2

# Evict existing pods (safely move them)
# Note: DaemonSets (like Flannel/MetalLB) will be ignored
kubectl drain worker-1 worker-2 --ignore-daemonsets --delete-emptydir-data
```

### Step 2: Shutdown Worker Nodes
SSH into each **Worker** node (`worker-1`, `worker-2`) and shut them down:

```bash
# On Worker 1
sudo poweroff

# On Worker 2
sudo poweroff
```
*Wait a minute until the LEDs on the Pis stop flickering and go solid red (or turn off if you have a fancy case).*

### Step 3: Shutdown Master Node
After workers are down, shut down the **Master**:

```bash
# On Master
kubectl cordon control-plane
kubectl drain control-plane --ignore-daemonsets --delete-emptydir-data
sudo poweroff
```

### Step 4: Unplug Power
Once all Pis have shut down (green activity LEDs are off), you can safely unplug the power.

---

## 2. Startup Procedure

### Step 1: Power On
1.  **Plug in the Master Node first.**
    *   Give it 2-3 minutes to boot and start the API Server.
2.  **Plug in Worker Nodes.**

### Step 2: Verify Status
From your Mac or Master node:

```bash
kubectl get nodes
```
*   You should see all nodes. They might stay `NotReady` for a minute while Kubelet starts.
*   Eventually, they should all be `Ready`.

### Step 3: Uncordon Nodes (If you drained them)
If you drained the nodes earlier, they are currently marked "SchedulingDisabled". You need to re-enable them:

```bash
kubectl uncordon control-plane worker-1 worker-2
```

### Step 4: Check System Pods
Ensure core services are running:

```bash
kubectl get pods -A
```
*   Check that `coredns`, `flannel`, `metallb`, and `longhorn` pods are `Running`.

## Troubleshooting

**"The API Server won't start!"**
*   If you unplugged the Master without shutting down, the database (etcd) might be corrupt.
*   **Fix**: SSH into the master and check logs: `journalctl -u kubelet -f` or `crictl logs ...`.
*   Usually, a simple `sudo reboot` on the master fixes "stuck" states.

**Longhorn Volume Stuck Attaching/Detaching**
*   Sometimes a volume gets stuck if a node died abruptly.
*   Go to the Longhorn UI -> **Volumes**.
*   Select the stuck volume -> **Attach/Detach** -> **Detach**.
*   Then let Kubernetes re-attach it automatically.
