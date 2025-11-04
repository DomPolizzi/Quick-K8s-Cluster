# Kubernetes Multi-Node Cluster with Vagrant

A fully automated Kubernetes cluster setup using Vagrant and libvirt/KVM for CKA exam preparation.

## Cluster Specifications

- **Control Plane**: 1 node (2 CPU, 4GB RAM) - IP: 192.168.56.10
- **Workers**: 2 nodes (2 CPU, 4GB RAM each) - IPs: 192.168.56.11-12
- **Kubernetes Version**: v1.33.x
- **Container Runtime**: containerd
- **CNI Plugin**: Calico
- **DNS**: CoreDNS (default)
- **OS**: Ubuntu 22.04 LTS

## Prerequisites

- Debian-based host system (Debian/Ubuntu)
- At least 16GB RAM available (12GB for VMs + 4GB for host)
- Virtualization enabled in BIOS (VT-x/AMD-V)
- ~20GB free disk space

## Quick Start

### 1. Install Prerequisites

```bash
cd k8s-vagrant-cluster
./install-prereqs.sh
```

This script installs:
- KVM/libvirt
- Vagrant
- vagrant-libvirt plugin
- Required dependencies

**IMPORTANT**: After running this script, log out and log back in for group changes to take effect.

### 2. Deploy the Cluster

```bash
./deploy.sh
```

This will:
- Download Ubuntu 22.04 box (first time only)
- Create 3 VMs (1 control plane + 2 workers)
- Install Kubernetes components
- Initialize the cluster
- Join worker nodes automatically

Deployment takes 10-15 minutes depending on your internet connection.

### 3. Access the Cluster

```bash
# SSH into control plane
vagrant ssh controlplane

# Verify cluster
kubectl get nodes
kubectl get pods -A

# Test deployment
kubectl create deployment nginx --image=nginx
kubectl get pods
```

## Common Operations

### View Cluster Status

```bash
# From host
vagrant ssh controlplane -c "kubectl get nodes"

# SSH into control plane
vagrant ssh controlplane
kubectl get nodes -o wide
kubectl get pods -A
```

### SSH into Nodes

```bash
vagrant ssh controlplane  # Control plane node
vagrant ssh worker1       # Worker node 1
vagrant ssh worker2       # Worker node 2
```

### Stop the Cluster

```bash
vagrant halt              # Stop all nodes
vagrant halt controlplane # Stop specific node
```

### Start Stopped Cluster

```bash
vagrant up               # Start all nodes
vagrant up worker1       # Start specific node
```

### Destroy and Rebuild

```bash
# Complete teardown
vagrant destroy -f

# Rebuild from scratch
vagrant destroy -f && vagrant up
```

### View VM Status

```bash
vagrant status           # Show all VMs
vagrant global-status    # Show all Vagrant VMs on system
```

## Using kubectl from Host

To manage the cluster from your host machine without SSH:

```bash
# Copy kubeconfig from control plane
vagrant ssh controlplane -c 'cat ~/.kube/config' > ~/.kube/k8s-vagrant-config

# Use the config
export KUBECONFIG=~/.kube/k8s-vagrant-config
kubectl get nodes

# Or merge with existing config
KUBECONFIG=~/.kube/config:~/.kube/k8s-vagrant-config kubectl config view --flatten > ~/.kube/merged-config
mv ~/.kube/merged-config ~/.kube/config
kubectl config use-context kubernetes-admin@kubernetes
```

## Customization

### Change Number of Workers

Edit `Vagrantfile`:

```ruby
NUM_WORKER_NODES = 3  # Change from 2 to desired number
```

### Adjust Resource Allocation

Edit `Vagrantfile` to change CPU/memory:

```ruby
v.memory = 8192  # Increase RAM to 8GB
v.cpus = 4       # Increase CPUs to 4
```

### Change IP Range

Edit `Vagrantfile`:

```ruby
IP_BASE = "192.168.57."  # Change subnet
```

### Use Different Kubernetes Version

Edit `scripts/common.sh` and change the repository version:

```bash
# From v1.33 to v1.34 (example)
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

## Troubleshooting

### VMs Not Starting

```bash
# Check libvirt is running
sudo systemctl status libvirtd

# Check your user groups (should include libvirt and kvm)
groups

# Restart libvirt
sudo systemctl restart libvirtd
```

### Network Issues

```bash
# Check libvirt network
sudo virsh net-list --all

# Restart default network
sudo virsh net-start default
```

### Worker Nodes Not Joining

```bash
# SSH into worker and check logs
vagrant ssh worker1
sudo journalctl -u kubelet -f

# On control plane, regenerate join token
vagrant ssh controlplane
kubeadm token create --print-join-command
```

### Clean State Reset

```bash
# Destroy everything and start fresh
vagrant destroy -f
rm -f join-command.sh
vagrant up
```

### View Provisioning Logs

```bash
# See detailed output during vagrant up
vagrant up --debug

# Re-run provisioning on existing VM
vagrant provision controlplane
```

## CKA Exam Practice Tips

This cluster closely mimics the CKA exam environment:

1. **Practice kubeadm**: The exam uses kubeadm for cluster management
2. **Learn kubectl shortcuts**: Configured with `k` alias and bash completion
3. **No GUI**: All practice should be done via SSH/terminal
4. **System pods**: Practice troubleshooting kube-system components
5. **Multi-node**: Test scheduling, node affinity, taints/tolerations
6. **Networking**: Calico CNI for network policy practice

### Recommended Practice Areas

```bash
# Node management
kubectl drain worker1 --ignore-daemonsets
kubectl uncordon worker1
kubectl cordon worker2

# etcd backup/restore
ETCDCTL_API=3 etcdctl snapshot save /tmp/backup.db

# Cluster upgrade
kubectl drain controlplane --ignore-daemonsets
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm=1.33.x-* && sudo apt-mark hold kubeadm
sudo kubeadm upgrade apply v1.33.x

# Troubleshooting
kubectl get events --sort-by='.lastTimestamp'
kubectl logs -n kube-system <pod-name>
journalctl -u kubelet
```

## File Structure

```
k8s-vagrant-cluster/
├── README.md              # This file
├── Vagrantfile           # Vagrant configuration
├── install-prereqs.sh    # Prerequisites installation
├── deploy.sh             # Deployment automation
└── scripts/
    ├── common.sh         # Common setup for all nodes
    ├── controlplane.sh   # Control plane initialization
    └── worker.sh         # Worker node setup
```

## What Gets Installed

### All Nodes
- containerd runtime
- kubeadm, kubelet, kubectl (v1.33)
- bash-completion
- kubectl alias (`k`) and completion

### Control Plane
- Kubernetes control plane components
- Calico CNI plugin
- Admin kubeconfig at `/home/vagrant/.kube/config`

### Worker Nodes
- Kubelet and kube-proxy
- Joins cluster automatically

## Networking Details

- **Pod Network CIDR**: 10.244.0.0/16
- **Service CIDR**: 10.96.0.0/12 (Kubernetes default)
- **VM Network**: 192.168.56.0/24
- **CNI**: Calico (supports Network Policies)

## Resource Requirements

Per VM:
- 2 vCPUs
- 4GB RAM
- ~10GB disk

Total:
- 6 vCPUs
- 12GB RAM
- ~30GB disk

## License

MIT

## Contributing

Feel free to customize and adapt for your needs. This is designed specifically for CKA exam preparation.
