# Phase 1: Hardware & OS Setup Guide

Follow these steps to prepare your 3 Raspberry Pi nodes for Kubernetes.

## 1. Flash Raspberry Pi OS (Headless Setup)

We will use **Raspberry Pi Imager** to flash the OS and pre-configure SSH, Hostnames, and User accounts. This avoids needing a monitor/keyboard for the Pis.

**Repeat this process for all 3 SD Cards:**

1.  **Download & Install** [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2.  **OS Selection**: Choose `Raspberry Pi OS (other)` -> `Raspberry Pi OS Lite (64-bit)`.
3.  **Storage**: Select your SD card.
4.  **Settings (The Gear Icon)** - **CRITICAL STEP**:
    *   **Hostname**: Set unique hostnames for each card (User preference, but we use these for this guide):
        *   Card 1: `control-plane`
        *   Card 2: `worker-1`
        *   Card 3: `worker-2`
    *   **Enable SSH**: Check this box. Use `Password authentication` (or public-key if you prefer).
    *   **Set username and password**:
        *   User: `pi` (or your preferred user)
        *   Password: [Secure Password]
    *   **Configure Wireless LAN** (Optional): If using Wi-Fi, set SSID/Pass. **Ethernet is highly recommended** for stability.
    *   **Set Locale settings**: Time zone and Keyboard layout.

5.  **Write**: Flash the data.

## 2. Boot & Network Configuration

1.  Insert SD cards into the Raspberry Pis.
2.  Connect them to power and your network switch/router.
3.  **Router Configuration**:
    *   Log into your router's admin page.
    *   Find the "DHCP Reservation" or "Static Lease" section.
    *   Identify the 3 Pis (look for hostnames `control-plane`, etc., or OUI starting with `b8:27:eb` or `dc:a6:32`).
    *   Assign **Static IP addresses**. Example:
        *   `control-plane`: `192.168.100.50`
        *   `worker-1`: `192.168.100.53`
        *   `worker-2`: `192.168.100.55`
4.  **Reboot** the Pis (recycle power) to ensure they pick up the new IPs.

## 3. Verify Connectivity

From your Mac terminal, try to SSH into each node:

```bash
ssh pi@192.168.100.50  # Type 'yes' to accept fingerprint
ssh pi@192.168.100.53
ssh pi@192.168.100.55
```

## 4. System Updates & Cgroups (Required for K8s)

Run the following commands on **ALL 3 Nodes**:

### A. Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### B. Enable Cgroups
Kubernetes needs `cgroup_memory=1` and `cgroup_enable=memory` typically enabled in the kernel command line on Raspberry Pi OS.

1.  Edit `cmdline.txt`:
    ```bash
    sudo nano /boot/firmware/cmdline.txt
    # Note: On older OS versions it might be /boot/cmdline.txt
    ```
2.  **Append** the following to the end of the line (do not add a new line, just add a space and this text):
    ```text
    cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
    ```
3.  **Save & Exit**: `Ctrl+O`, `Enter`, `Ctrl+X`.
4.  **Reboot**:
    ```bash
    sudo reboot
    ```
