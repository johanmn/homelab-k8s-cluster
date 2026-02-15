# Phase 5: Distributed Storage with Longhorn

In a real environment, pods are ephemeral. If a database pod restarts on a different node, the data disappears unless you have **Persistent Storage**.
We will install **Longhorn**, a powerful Cloud-Native distributed block storage system. It replicates data across your Pis, so if one Pi dies, your data is safe!

## 1. Install Prerequisites (All Nodes)
Longhorn requires `open-iscsi` and `nfs-common` to manage block devices.

**Run on ALL 3 Nodes:**
```bash
sudo apt-get install -y open-iscsi nfs-common cryptsetup dmsetup
sudo systemctl enable --now iscsid
```

## 2. Install Longhorn
We will use `kubectl` to install Longhorn directly from their official manifest.

**Run on Master Node:**
```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml
```

**Monitor Installation:**
This pulls many images and starts many system pods. It might take 3-5 minutes on Raspberry Pis.
```bash
kubectl get pods -n longhorn-system --watch
```
*   Wait until all pods are `Running` (it's okay if some restart a few times initially).
*   Press `Ctrl+C` once everything looks stable.

## 3. Access the Longhorn UI
Longhorn has a beautiful dashboard. Let's expose it via MetalLB so you can see it.

**Create `longhorn-service.yaml`:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: longhorn-frontend-lb
  namespace: longhorn-system
spec:
  selector:
    app: longhorn-ui
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    targetPort: 8000
```

**Apply it:**
```bash
kubectl apply -f longhorn-service.yaml
```

**Get the IP:**
```bash
kubectl get svc -n longhorn-system longhorn-frontend-lb
```
*   Look for the `EXTERNAL-IP` (e.g., `192.168.100.201`).
*   Open that IP in your browser.

## 4. Verify & Test Storage
Let's verify the system works by creating a Persistent Volume Claim (PVC).

**Create `test-pvc.yaml`:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
```

**Apply it:**
```bash
kubectl apply -f test-pvc.yaml
```

**Check status:**
```bash
kubectl get pvc
```
*   You should see status `Bound`. This means Longhorn successfully provisioned a 1GB virtual volume for you!

## Summary
You now have a storage area network (SAN) running on your cluster.
*   **Green Dashboard**: Go to the UI IP. You should see 3 nodes and "Healthy" status.
*   **Replication**: Longhorn defaults to 3 replicas. Since you have 3 nodes, every piece of data is stored on ALL 3 nodes.

**Note on SD Cards:** Longhorn writes data to `/var/lib/longhorn`. Heavy database usage can wear out SD cards. For a learning lab, this is fine, but in production, you'd want USB SSDs attached to the Pis.
