# Kubernetes Multi-Node Cluster with Vagrant and Hyper-V

A fully automated Kubernetes cluster setup using Vagrant and Hyper-V for Windows hosts. Perfect for CKA exam preparation, development, and testing.

## Cluster Specifications

- **Control Plane**: 1 node (2 CPU, 4GB RAM) - IP: 192.168.56.10
- **Workers**: 2 nodes (2 CPU, 4GB RAM each) - IPs: 192.168.56.11-12
- **Kubernetes Version**: v1.33.x
- **Container Runtime**: containerd
- **CNI Plugin**: Calico
- **DNS**: CoreDNS (default)
- **OS**: Ubuntu 22.04 LTS

## Prerequisites

### System Requirements
- **OS**: Windows 10/11 Pro, Enterprise, or Education (Home edition does NOT support Hyper-V)
  - Alternative: Windows Server 2016 or later
- **RAM**: At least 16GB (12GB for VMs + 4GB for host)
- **CPU**: Virtualization enabled in BIOS (Intel VT-x or AMD-V)
- **Disk**: ~30GB free disk space
- **Hyper-V**: Must be available (not available on Windows Home)

### Software Requirements
- PowerShell 5.1 or later (included in Windows 10/11)
- Administrator privileges
- Internet connection for initial setup

## Quick Start

### 1. Install Prerequisites

Open PowerShell as Administrator:

```powershell
# Right-click PowerShell and select "Run as Administrator"
cd path\to\Quick-K8s-Cluster\hyper-v

# Run the prerequisites installer
.\Install-Prerequisites.ps1
```

This script will:
- Check Windows version and edition
- Enable Hyper-V (if not already enabled)
- Install Chocolatey package manager
- Install Vagrant
- Verify Hyper-V virtual switch configuration
- Check system resources

**IMPORTANT**: If Hyper-V was just enabled, you MUST reboot your computer before proceeding.

### 2. Deploy the Cluster

After prerequisites are installed (and after reboot if needed):

```powershell
# Open PowerShell as Administrator
cd path\to\Quick-K8s-Cluster\hyper-v

# Run the deployment script
.\Deploy.ps1
```

This will:
- Download Ubuntu 22.04 box (first time only, ~500MB)
- Create 3 VMs (1 control plane + 2 workers)
- Install Kubernetes components
- Initialize the cluster
- Join worker nodes automatically

**Note**: During deployment, you'll be prompted for your Windows username and password for SMB folder sharing.

Deployment takes 15-20 minutes depending on your internet connection.

### 3. Access the Cluster

```powershell
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

```powershell
# From PowerShell (host)
vagrant ssh controlplane -c "kubectl get nodes"

# SSH into control plane
vagrant ssh controlplane
kubectl get nodes -o wide
kubectl get pods -A
```

### SSH into Nodes

```powershell
vagrant ssh controlplane  # Control plane node
vagrant ssh worker1       # Worker node 1
vagrant ssh worker2       # Worker node 2
```

### Stop the Cluster

```powershell
vagrant halt              # Stop all nodes
vagrant halt controlplane # Stop specific node
```

### Start Stopped Cluster

```powershell
vagrant up               # Start all nodes
vagrant up worker1       # Start specific node
```

### Destroy and Rebuild

```powershell
# Complete teardown
vagrant destroy -f

# Rebuild from scratch
vagrant destroy -f
vagrant up --provider hyperv

# Or use the deployment script
.\Deploy.ps1 -Destroy
```

### View VM Status

```powershell
vagrant status           # Show all VMs in this directory
vagrant global-status    # Show all Vagrant VMs on system

# View VMs in Hyper-V Manager
# Press Windows key, type "Hyper-V Manager"
```

## Using kubectl from Host

To manage the cluster from your Windows host without SSH:

### Option 1: Copy kubeconfig

```powershell
# Create .kube directory if it doesn't exist
New-Item -ItemType Directory -Force -Path $HOME\.kube

# Copy kubeconfig from control plane
vagrant ssh controlplane -c "cat ~/.kube/config" | Out-File -Encoding utf8 $HOME\.kube\k8s-vagrant-config

# Set environment variable
$env:KUBECONFIG="$HOME\.kube\k8s-vagrant-config"

# Install kubectl on Windows (if not already installed)
choco install kubernetes-cli -y

# Use kubectl
kubectl get nodes
```

### Option 2: Merge with existing kubeconfig

```powershell
# If you already have kubectl configured
$env:KUBECONFIG="$HOME\.kube\config;$HOME\.kube\k8s-vagrant-config"
kubectl config view --flatten | Out-File -Encoding utf8 $HOME\.kube\merged-config
Move-Item -Force $HOME\.kube\merged-config $HOME\.kube\config
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
h.memory = 8192  # Increase RAM to 8GB
h.cpus = 4       # Increase CPUs to 4
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

### Nested Virtualization Error

**Error**: "The virtual machine could not be started because of a configuration error. Disable nested virtualization..."

**Solution**: This is already fixed in the Vagrantfile (line 27 sets `enable_virtualization_extensions = false`). If you see this error:

```powershell
# Clean up and retry
vagrant destroy -f
.\Deploy.ps1
```

Nested virtualization is not required for Kubernetes as it uses containers, not VMs.

### Hyper-V Not Available

**Error**: "Windows Home edition does not support Hyper-V"

**Solution**: Upgrade to Windows 10/11 Pro, Enterprise, or Education. Windows Home does not support Hyper-V.

### VMs Not Starting

```powershell
# Check Hyper-V service
Get-Service vmms

# Start Hyper-V service if stopped
Start-Service vmms

# Check VM status in Hyper-V Manager
# Windows Key -> "Hyper-V Manager"

# Restart Hyper-V service
Restart-Service vmms
```

### Network Issues

```powershell
# Check Hyper-V virtual switches
Get-VMSwitch

# The VMs should use "Default Switch" which is created automatically
# If missing, check Hyper-V Manager -> Virtual Switch Manager

# Check VM network adapters
Get-VM | Get-VMNetworkAdapter
```

### SMB Authentication Failures

**Error**: "SMB credentials required"

**Solution**: The deployment script will prompt for credentials. Use your Windows login username and password.

To set manually:

```powershell
$env:VAGRANT_SMB_USERNAME = "your-username"
$env:VAGRANT_SMB_PASSWORD = "your-password"
```

### Worker Nodes Not Joining

```powershell
# SSH into worker and check logs
vagrant ssh worker1
sudo journalctl -u kubelet -f

# On control plane, regenerate join token
vagrant ssh controlplane
kubeadm token create --print-join-command
```

### Clean State Reset

```powershell
# Destroy everything and start fresh
vagrant destroy -f
Remove-Item join-command.sh -ErrorAction SilentlyContinue
vagrant up --provider hyperv
```

### View Provisioning Logs

```powershell
# See detailed output during vagrant up
vagrant up --debug

# Re-run provisioning on existing VM
vagrant provision controlplane
```

### Firewall Blocking Connections

If Windows Firewall is blocking connections:

```powershell
# Check firewall rules
Get-NetFirewallProfile

# You may need to allow Vagrant/Hyper-V through the firewall
# Windows Security -> Firewall & network protection -> Allow an app through firewall
```

### VMs Running but Can't SSH

```powershell
# Check if VMs have network connectivity
# Open Hyper-V Manager and connect to VM console

# Verify VM is getting IP addresses
vagrant ssh controlplane
ip addr show

# Check SSH service
sudo systemctl status ssh
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
hyper-v/
├── README.md                    # This file
├── Vagrantfile                  # Hyper-V Vagrant configuration
├── Install-Prerequisites.ps1    # Prerequisites installation script
├── Deploy.ps1                   # Deployment automation script
└── scripts/
    ├── common.sh               # Common setup for all nodes
    ├── controlplane.sh         # Control plane initialization
    └── worker.sh               # Worker node setup
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
- **VM Network**: 192.168.56.0/24 (static IPs on eth1)
- **CNI**: Calico (supports Network Policies)
- **Hyper-V Switch**: Default Switch (NAT mode)

## Resource Requirements

Per VM:
- 2 vCPUs
- 4GB RAM
- ~10GB disk

Total:
- 6 vCPUs
- 12GB RAM
- ~30GB disk

## Performance Tips

1. **Close unnecessary applications** before starting VMs
2. **Use SSD storage** for better performance
3. **Allocate more resources** if available (edit Vagrantfile)
4. **Disable Windows Search** indexing on VM disk locations
5. **Use wired network** for better stability

## Differences from Linux/libvirt Version

This Hyper-V version differs from the libvirt version in:

- **Provider**: Uses Hyper-V instead of libvirt/KVM
- **Scripts**: PowerShell instead of Bash for host operations
- **Networking**: Hyper-V virtual switches instead of libvirt networks
- **Synced folders**: SMB instead of rsync
- **Host OS**: Windows instead of Linux

The Kubernetes cluster itself is identical.

## Known Limitations

1. **Windows Home**: Not supported (Hyper-V not available)
2. **SMB**: Requires Windows credentials for folder sharing
3. **Nested virtualization**: May have performance impact
4. **Snapshot**: Vagrant snapshots work differently on Hyper-V

## Additional Resources

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Hyper-V Documentation](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [CKA Exam Curriculum](https://github.com/cncf/curriculum)

## License

MIT

## Contributing

Feel free to customize and adapt for your needs. This is designed specifically for CKA exam preparation on Windows hosts.

## Support

For issues specific to:
- **Vagrant**: Check [Vagrant Issues](https://github.com/hashicorp/vagrant/issues)
- **Hyper-V**: Check Windows Event Viewer and Hyper-V logs
- **Kubernetes**: Check cluster logs with `kubectl logs` and `journalctl`
