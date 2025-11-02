# Quick Start Guide - Hyper-V Edition

## Prerequisites Checklist

- [ ] Windows 10/11 Pro/Enterprise/Education (NOT Home)
- [ ] At least 16GB RAM
- [ ] Administrator access
- [ ] Virtualization enabled in BIOS

## Installation (5 minutes)

1. **Open PowerShell as Administrator**
   - Press `Windows + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Navigate to the directory**
   ```powershell
   cd path\to\Quick-K8s-Cluster\hyper-v
   ```

3. **Run prerequisites installer**
   ```powershell
   .\Install-Prerequisites.ps1
   ```

4. **Reboot if prompted** (only if Hyper-V was just enabled)

## Deployment (15-20 minutes)

1. **Open PowerShell as Administrator** (after reboot if needed)
   ```powershell
   cd path\to\Quick-K8s-Cluster\hyper-v
   ```

2. **Deploy the cluster**
   ```powershell
   .\Deploy.ps1
   ```

3. **Enter your Windows credentials** when prompted (for SMB folder sharing)
   - Username: Your Windows login username
   - Password: Your Windows login password

4. **Wait for deployment** to complete (~15-20 minutes)

## Verify Cluster (2 minutes)

```powershell
# Check cluster status
vagrant ssh controlplane -c "kubectl get nodes"

# Should show 3 nodes (1 control plane + 2 workers) all Ready

# Check all pods
vagrant ssh controlplane -c "kubectl get pods -A"

# All pods should be Running
```

## Daily Usage

### Start Cluster
```powershell
vagrant up
```

### Stop Cluster
```powershell
vagrant halt
```

### SSH into Control Plane
```powershell
vagrant ssh controlplane
```

### SSH into Workers
```powershell
vagrant ssh worker1
vagrant ssh worker2
```

### Run kubectl Commands from Host
```powershell
vagrant ssh controlplane -c "kubectl get nodes"
vagrant ssh controlplane -c "kubectl get pods -A"
vagrant ssh controlplane -c "kubectl create deployment nginx --image=nginx"
```

### Check Status
```powershell
vagrant status
```

### Destroy Cluster
```powershell
vagrant destroy -f

# Or rebuild completely
.\Deploy.ps1 -Destroy
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

### Can't start VMs?
```powershell
# Check Hyper-V service
Get-Service vmms
Start-Service vmms

# Check in Hyper-V Manager
# Windows Key -> type "Hyper-V Manager"
```

### Network issues?
```powershell
# Check virtual switches
Get-VMSwitch

# Restart deployment
vagrant destroy -f
.\Deploy.ps1
```

### Need to reset everything?
```powershell
vagrant destroy -f
Remove-Item join-command.sh -ErrorAction SilentlyContinue
.\Deploy.ps1
```

## Resource Monitoring

### Check VM Resource Usage
```powershell
# In PowerShell
Get-VM | Where-Object {$_.Name -like "k8s-*"} | Select-Object Name, State, CPUUsage, MemoryAssigned

# Or open Task Manager -> Performance tab
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

1. **Always run PowerShell as Administrator** for Vagrant commands
2. **Don't close PowerShell** during deployment
3. **Use Hyper-V Manager** to see VMs visually (Windows Key -> "Hyper-V Manager")
4. **Save your work** before stopping VMs (kubectl applies are persistent)
5. **Stop VMs when not in use** to free up RAM (`vagrant halt`)

## Next Steps

- Practice CKA exam scenarios
- Deploy sample applications
- Test networking with Calico policies
- Practice cluster upgrades
- Test backup and restore with etcd

---

**Need help?** Check the full README.md for detailed troubleshooting and advanced configuration options.
