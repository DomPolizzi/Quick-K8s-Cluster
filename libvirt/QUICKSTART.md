# Quick Start Guide - libvirt/KVM Edition

## Prerequisites Checklist

- [ ] Debian-based Linux (Debian/Ubuntu)
- [ ] At least 16GB RAM
- [ ] Virtualization enabled in BIOS (VT-x/AMD-V)
- [ ] ~20GB free disk space

## Installation (5 minutes)

1. **Navigate to the directory**
   ```bash
   cd Quick-K8s-Cluster/libvirt
   ```

2. **Run prerequisites installer**
   ```bash
   ./install-prereqs.sh
   ```

3. **Log out and log back in** (required for group changes to take effect)

## Deployment (10-15 minutes)

1. **Navigate to the directory**
   ```bash
   cd Quick-K8s-Cluster/libvirt
   ```

2. **Deploy the cluster**
   ```bash
   ./deploy.sh
   ```

3. **Wait for deployment** to complete (~10-15 minutes)

## Verify Cluster (2 minutes)

```bash
# Check cluster status
vagrant ssh controlplane -c "kubectl get nodes"

# Should show 3 nodes (1 control plane + 2 workers) all Ready

# Check all pods
vagrant ssh controlplane -c "kubectl get pods -A"

# All pods should be Running
```

## Daily Usage

### Start Cluster
```bash
vagrant up
```

### Stop Cluster
```bash
vagrant halt
```

### SSH into Control Plane
```bash
vagrant ssh controlplane
```

### SSH into Workers
```bash
vagrant ssh worker1
vagrant ssh worker2
```

### Run kubectl Commands from Host
```bash
vagrant ssh controlplane -c "kubectl get nodes"
vagrant ssh controlplane -c "kubectl get pods -A"
vagrant ssh controlplane -c "kubectl create deployment nginx --image=nginx"
```

### Check Status
```bash
vagrant status
```

### Destroy Cluster
```bash
vagrant destroy -f

# Or rebuild completely
vagrant destroy -f && vagrant up
```

## Common kubectl Commands (from inside controlplane)

```bash
# SSH first
vagrant ssh controlplane

# Then run these commands:
kubectl get nodes
kubectl get pods -A
kubectl get services
kubectl get deployments

# Create test deployment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get pods
kubectl get services

# Scale deployment
kubectl scale deployment nginx --replicas=3

# Delete deployment
kubectl delete deployment nginx
kubectl delete service nginx
```

## Troubleshooting

### VMs not starting?
```bash
# Check libvirt is running
sudo systemctl status libvirtd

# Check your user groups (should include libvirt and kvm)
groups

# Restart libvirt
sudo systemctl restart libvirtd
```

### Network issues?
```bash
# Check libvirt network
sudo virsh net-list --all

# Restart default network
sudo virsh net-start default
```

### Need to reset everything?
```bash
vagrant destroy -f
rm -f join-command.sh
vagrant up
```

## Resource Monitoring

### Check VM Resource Usage
```bash
# Using virt-manager GUI
virt-manager

# Or command line
virsh list --all
virsh dominfo <vm-name>
```

### Check from inside VMs
```bash
# SSH into a node
vagrant ssh controlplane

# Check resources
top
free -h
df -h
```

## Tips

1. **Use virt-manager** for a GUI view of your VMs
2. **Don't close terminal** during deployment
3. **Save your work** before stopping VMs (kubectl applies are persistent)
4. **Stop VMs when not in use** to free up RAM (`vagrant halt`)
5. **Log out and back in** after installing prerequisites (for group membership)

## Next Steps

- Practice CKA exam scenarios
- Deploy sample applications
- Test networking with Calico policies
- Practice cluster upgrades
- Test backup and restore with etcd

---
