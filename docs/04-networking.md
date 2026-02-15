# Phase 4: MetalLB Setup Guide (Load Balancer)

Now that we have a cluster, we need a way to access services from your home network. We will use **MetalLB** to give permissions keypods a "real" IP address from your router's subnet (e.g., `192.168.100.200`).

## 1. Prepare Kube-Proxy (Strict ARP)
MetalLB creates a simpler valid configuration if `strictARP` is enabled in the cluster.

Run this on the **Master node**:

```bash
# 1. Edit the configmap
kubectl edit configmap -n kube-system kube-proxy
```

*   This opens a text editor (like vi/nano).
*   Find `strictARP: false`.
*   Change it to `strictARP: true`.
*   Save and exit.

**Alternatively, run this one-liner:**
```bash
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

## 2. Install MetalLB
We will use the official manifest to install MetalLB.

```bash
# Apply the manifest
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

**Wait for the pods to be ready:**
```bash
kubectl get pods -n metallb-system --watch
```
*   Wait until you see `controller` and `speaker` pods in `Running` state (Wait about 1-2 mins).
*   Press `Ctrl+C` to stop watching.

## 3. Configure IP Address Pool
We need to tell MetalLB which IPs it is allowed to hand out.
**CRITICAL**: Pick a range that is **NOT** used by your DHCP server or other devices.
*   Your Nodes are `.50`, `.53`, `.55`.
*   *Suggestion*: Use `.200` to `.220` (check your router so no DHCP collision occurs).

**Create a file named `metallb-config.yaml`:**
```bash
nano metallb-config.yaml
```

**Paste this content:**
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.100.200-192.168.100.210  # <-- EDIT THIS RANGE IF NEEDED
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: homelab-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```

**Apply the configuration:**
```bash
kubectl apply -f metallb-config.yaml
```

## 4. Verification (The Moment of Truth)
Let's deploy a test Nginx server and see if it gets an IP.

1.  **Create an Nginx deployment:**
    ```bash
    kubectl create deploy nginx --image=nginx
    ```
2.  **Expose it as a LoadBalancer:**
    ```bash
    kubectl expose deploy nginx --port=80 --type=LoadBalancer
    ```
3.  **Check the Service:**
    ```bash
    kubectl get svc
    ```

**Output should look like:**
```text
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
kubernetes   ClusterIP      10.96.0.1       <none>            443/TCP        65m
nginx        LoadBalancer   10.105.x.x      192.168.100.200   80:31568/TCP   10s
```

*   If `EXTERNAL-IP` shows a real IP (e.g., `192.168.100.200` and NOT `<pending>`), SUCCESS!
*   Open your browser on your Mac and go to `http://192.168.100.200`. You should see "Welcome to nginx!".

**Once verified:**
You can delete the test service:
```bash
kubectl delete svc nginx
kubectl delete deploy nginx
```
