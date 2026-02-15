# 🍓 <img src="https://github.com/user-attachments/assets/30540933-e9fa-49e3-b819-7ba64f104878" width="31" height="31"> Raspberry Pi 5 Kubernetes Homelab Cluster

Welcome to my Kubernetes Homelab! This repository documents the journey of building a production-grade Kubernetes cluster from scratch using bare-metal hardware.

As a Cloud and DevOps Engineer, Kubernetes is part of my daily professional toolkit. This homelab represents my passion for the field, serving as a dedicated environment for learning, experimenting, and staying ahead of current technology trends.

> [!NOTE]
> 🌱 **Living Documentation**: This repository is not just a snapshot of the current setup. It is a living document that will grow and evolve as I continue to build, experiment, and add new features to my homelab journey. Stay tuned for updates!

## 🎯 Project Goals
The primary objective of this project is to simulate a real-world DevOps environment to:
*   Build and manage a Kubernetes cluster on bare-metal ARM architecture.
*   Implement Infrastructure-as-Code (IaC) and GitOps principles.
*   Master core Kubernetes concepts: Networking (CNI), Storage (CSI), and Load Balancing.
*   Demonstrate proficiency with industry-standard tools (Kubeadm, MetalLB, Longhorn, Prometheus).

## 🏗️ Hardware Setup
This cluster is built on the following hardware:

*   **Compute Nodes**: 3x [Raspberry Pi 5 (8GB RAM)](https://a.co/d/0ei9gwVh)
    *   `control-plane` (Master Node)
    *   `worker-1`
    *   `worker-2`
*   **Storage**: 3x SanDisk UHS-I 16GB MicroSD Cards (Bought locally) + Distributed Storage for Data
*   **Power**: 3x [RasTech 27W USB-C PD Power Supply](https://a.co/d/0es34iDz)
*   **Cooling & Case**: 1x [UCTRONICS Raspberry Pi Cluster Case](https://a.co/d/01hplHYI) with active cooling fans
*   **Network**: Home Router LAN Ports (Dedicated Gigabit Switch recommended)

## 🛠️ Software Stack
| Component | Technology | Version | Description |
| :--- | :--- | :--- | :--- |
| **OS** | Raspberry Pi OS Lite (64-bit) | Debian 13 (Trixie) | Lightweight, headless operating system. |
| **Container Runtime** | containerd | 1.7+ | Industry-standard container runtime. |
| **Orchestrator** | Kubernetes (K8s) | v1.32.x | Upstream Kubernetes bootstrapped via `kubeadm`. |
| **CNI (Network)** | Flannel | Latest | Simple L3 network fabric for pod communication. |
| **Load Balancer** | MetalLB | v0.14.x | Bare-metal load balancer (L2 mode) for external access. |
| **Storage (CSI)** | Longhorn | v1.6.x | Cloud-native distributed block storage. |

## 📂 Repository Structure

```tree
.
├── docs/                   # Detailed setup guides & documentation
│   ├── 01-hardware-prep.md # OS flashing & network config
│   ├── 02-prerequisites.md # Kernel modules, swap, & containerd setup
│   ├── 03-cluster-init.md  # Kubeadm init & worker joining
│   ├── 04-networking.md    # MetalLB installation & config
│   ├── 05-storage.md       # Longhorn storage setup
│   └── operations.md       # Graceful shutdown/restart procedures
├── scripts/                # Automation scripts
│   └── install_k8s_deps.sh # Script to install K8s dependencies
└── README.md               # This file
```

## 🚀 Getting Started
Check out the **[Docs](./docs/)** folder to follow the step-by-step installation process.

## 🤝 Key Learnings
*   **Bare Metal**: Configuring Linux kernel parameters (`cgroup_memory=1`, `swapoff`) manually.
*   **Networking**: Understanding L2 Load Balancing vs Cloud Load Balancers.
*   **Persistence**: Implementing distributed storage on ephemeral media.