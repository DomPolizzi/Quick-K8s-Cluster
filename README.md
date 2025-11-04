# Quick Kubernetes Cluster with Vagrant

A fully automated Kubernetes multi-node cluster setup using Vagrant for local development, testing, and CKA exam preparation.

## Overview

This repository provides automated Kubernetes cluster deployments for different hypervisors:

- **libvirt/KVM** - For Linux hosts (Debian/Ubuntu)
- **Hyper-V** - For Windows hosts (Windows 10/11 Pro/Enterprise/Education)

Both deployments create identical Kubernetes clusters with:
- **1 control plane node** (2 CPU, 4GB RAM)
- **2 worker nodes** (2 CPU, 4GB RAM each)
- **Kubernetes v1.33.x**
- **containerd runtime**
- **Calico CNI**
- **Ubuntu 22.04 LTS**

## Choose Your Deployment

### 🐧 Linux (libvirt/KVM)

For Debian-based Linux systems with libvirt/KVM:

```bash
cd libvirt/
./install-prereqs.sh
# Log out and log back in
./deploy.sh
```

**Requirements:**
- Debian/Ubuntu Linux
- 16GB RAM minimum
- Virtualization enabled (VT-x/AMD-V)

📖 **[libvirt Quick Start →](libvirt/QUICKSTART.md)** | **[Full Docs →](libvirt/README.md)**

---

### 🪟 Windows (Hyper-V)

For Windows systems with Hyper-V:

```powershell
cd hyper-v\
.\Install-Prerequisites.ps1
# Reboot if needed
.\Deploy.ps1
```

**Requirements:**
- Windows 10/11 Pro/Enterprise/Education (NOT Home)
- 16GB RAM minimum
- Hyper-V feature available

📖 **[Hyper-V Quick Start →](hyper-v/QUICKSTART.md)** | **[Full Docs →](hyper-v/README.md)**

---

## Quick Commands

```bash
# Start cluster
vagrant up

# Stop cluster
vagrant halt

# Destroy cluster
vagrant destroy -f

# SSH into nodes
vagrant ssh controlplane
vagrant ssh worker1

# Run kubectl
vagrant ssh controlplane -c "kubectl get nodes"
```

## Project Structure

```
Quick-K8s-Cluster/
├── README.md                    # This file
├── libvirt/                     # Linux/KVM deployment
│   ├── QUICKSTART.md
│   ├── README.md
│   ├── Vagrantfile
│   ├── deploy.sh
│   ├── install-prereqs.sh
│   └── scripts/
└── hyper-v/                     # Windows/Hyper-V deployment
    ├── QUICKSTART.md
    ├── README.md
    ├── Vagrantfile
    ├── Deploy.ps1
    ├── Install-Prerequisites.ps1
    ├── Check-Status.ps1
    ├── Helpers.ps1
    └── scripts/
```

## System Requirements

**Minimum:**
- RAM: 16GB (12GB for VMs + 4GB for host)
- CPU: 4+ cores with virtualization support
- Disk: 30GB free space
- Network: Internet connection

## Platform Comparison

| Feature | libvirt/KVM | Hyper-V |
|---------|-------------|---------|
| **Host OS** | Linux | Windows 10/11 Pro+ |
| **Hypervisor** | KVM/libvirt | Hyper-V |
| **Management** | Bash scripts | PowerShell scripts |
| **Networking** | Static IPs | DHCP |

## Use Cases

- 🎓 **Learning**: CKA/CKAD exam preparation
- 💻 **Development**: Local Kubernetes development
- 🧪 **Testing**: Application testing in multi-node environment
- 🔬 **Experimentation**: Try Kubernetes features safely

## Getting Started

1. Choose your platform (Linux or Windows)
2. Navigate to the directory (`libvirt/` or `hyper-v/`)
3. Follow the QUICKSTART.md
4. Deploy in under 20 minutes!

---

**Ready to get started?**

- 🐧 **[Linux/libvirt Quick Start →](libvirt/QUICKSTART.md)**
- 🪟 **[Windows/Hyper-V Quick Start →](hyper-v/QUICKSTART.md)**

## License

MIT
