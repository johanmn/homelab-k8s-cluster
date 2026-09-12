# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Documentation and automation for a 3-node bare-metal Kubernetes cluster running on Raspberry Pi 5 hardware (ARM64). There is no application source code, no build system, and no test suite — the deliverables are the phased setup guides in `docs/` and the single provisioning script in `scripts/`.

The "system under change" is real hardware. Nothing here can be verified by running it locally: every command in the docs is executed over SSH on the Pis themselves, and `kubectl` commands run on the control-plane node (its `~/.kube/config` is copied from `/etc/kubernetes/admin.conf` during Phase 3).

## Commands

There is no build, lint, or test step. The only executable is the provisioning script, which is run **on each node**, not on the dev machine:

```bash
# Syntax-check the script locally before committing (no shellcheck installed)
bash -n scripts/install_k8s_deps.sh

# Actual use: copy to each of the 3 nodes and run there
scp scripts/install_k8s_deps.sh <user>@<node-ip>:~/
ssh <user>@<node-ip> 'bash ~/install_k8s_deps.sh'
```

Verification is done with `kubectl` on the control plane — `kubectl get nodes -o wide` (all 3 `Ready`) and `kubectl get pods -A` (`coredns`, `kube-flannel`, `metallb-system`, `longhorn-system` all `Running`).

## Architecture

The cluster is built in five strictly ordered phases; each guide assumes the previous one completed. Editing one phase usually means checking the phases downstream of it.

| Phase | Guide | Establishes |
| :--- | :--- | :--- |
| 1 | `docs/01-hardware-prep.md` | OS flash, hostnames, static DHCP reservations, cgroup kernel args in `cmdline.txt` |
| 2 | `docs/02-prerequisites.md` | swap off, `overlay`/`br_netfilter`, sysctl bridge+forward, containerd with `SystemdCgroup = true`, kubeadm/kubelet/kubectl pinned via apt-mark hold |
| 3 | `docs/03-cluster-init.md` | `kubeadm init --pod-network-cidr=10.244.0.0/16`, Flannel CNI, worker join |
| 4 | `docs/04-networking.md` | kube-proxy `strictARP: true`, MetalLB, `IPAddressPool` + `L2Advertisement` |
| 5 | `docs/05-storage.md` | `open-iscsi`/`nfs-common` on all nodes, Longhorn, `longhorn` StorageClass |

`docs/operations.md` is separate from the build sequence: it covers the cordon/drain → power-off → power-on → uncordon cycle, which matters because abrupt shutdowns corrupt etcd and strand Longhorn volumes.

### Cross-file couplings to preserve

These constraints are invisible from any single file — changing one side without the other breaks the cluster:

- **`scripts/install_k8s_deps.sh` is the automated form of `docs/02-prerequisites.md`.** They must stay in step. (Note the script uses `/etc/apt/keyrings/docker.asc` where the doc uses `docker.gpg` — harmless, but a real divergence to be aware of.)
- **Pod CIDR `10.244.0.0/16` is Flannel's default.** It is hardcoded in the `kubeadm init` flag in Phase 3. Swapping the CNI means changing both.
- **Kubernetes minor version appears in three places**: the README software-stack table, the apt repo URLs in `docs/02`, and the same URLs in `install_k8s_deps.sh`. A version bump touches all three.
- **Pinned component versions** — MetalLB `v0.14.3` and Longhorn `v1.6.0` — are embedded in the manifest URLs in `docs/04` and `docs/05` and mirrored in the README table.
- **MetalLB's address pool must not overlap the router's DHCP range**, and the node IPs sit in the same subnet. Phases 1, 4, and 5 all reference this address plan.

### Placeholder convention (important)

This is a public showcase repository. The `pi` username, the `192.168.100.x` addresses, and the MetalLB pool range in the docs are **deliberate placeholders**, not the real homelab values. Do not "correct" them to real infrastructure details, and do not commit actual hostnames, IPs, tokens, or join commands. Keep new docs in the same placeholder style.

## Conventions

- **Guides are prose walkthroughs**, not runbooks to be condensed: numbered steps, fenced command blocks, an explicit verification step with expected output, and a note on what "normal but alarming" output looks like (e.g. `NotReady` before the CNI is installed). Match that shape when adding a phase.
- New phases follow the `NN-topic.md` naming and are added to the README's repository-structure tree and software-stack table.
- **Branching** (see `CONTRIBUTING.md`): branch from `main` with `feat/`, `fix/`, `docs/`, or `chore/` prefixes; open a PR against `main`. `main` is the single source of truth and reflects the actually-deployed cluster state — do not merge documentation for something not yet running.
- **Commits** follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, …).
