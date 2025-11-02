#!/bin/bash
set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${GREEN}=== Kubernetes Cluster Deployment Script ===${NC}\n"

# Combine all prerequisite checks
check_prerequisites() {
    local errors=()
    
    command -v vagrant &> /dev/null || errors+=("Vagrant is not installed")
    vagrant plugin list 2>/dev/null | grep -q vagrant-libvirt || errors+=("vagrant-libvirt plugin is not installed")
    groups | grep -q libvirt || errors+=("Current user is not in the 'libvirt' group. Log out and back in after running install-prereqs.sh")
    
    if [ ${#errors[@]} -gt 0 ]; then
        echo -e "${RED}Error: Prerequisites not met:${NC}"
        printf '  - %s\n' "${errors[@]}"
        echo -e "\nPlease run ${GREEN}./install-prereqs.sh${NC} first"
        exit 1
    fi
}

check_prerequisites

echo -e "${BLUE}This will create a Kubernetes cluster with:${NC}"
echo "  - 1 control plane node (2 CPU, 4GB RAM) - IP: 192.168.56.10"
echo "  - 2 worker nodes (2 CPU, 4GB RAM each) - IPs: 192.168.56.11-12"
echo "  - Kubernetes v1.33.x with Calico CNI and CoreDNS"
echo ""

# Ask for confirmation
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || { echo -e "${YELLOW}Deployment cancelled${NC}"; exit 0; }

# Clean up any existing join-command.sh
rm -f join-command.sh

echo -e "\n${YELLOW}Starting cluster deployment...${NC}"
echo -e "This will take 10-15 minutes depending on your internet connection and system resources.\n"

# Start the cluster
if ! vagrant up; then
    echo -e "\n${RED}Error: Cluster deployment failed${NC}"
    echo -e "Check the output above for details. Common issues:"
    echo -e "  - Insufficient system resources (need 12GB RAM total)"
    echo -e "  - Network connectivity problems"
    echo -e "  - libvirt/KVM issues"
    exit 1
fi

echo -e "\n${GREEN}=== Cluster Deployment Complete! ===${NC}\n"

# Execute multiple kubectl commands in a single SSH session
echo -e "${BLUE}Cluster Information:${NC}"
if vagrant ssh controlplane -c 'kubectl get nodes -o wide && echo && kubectl get pods -A' 2>/dev/null; then
    :
else
    echo -e "${YELLOW}Warning: Could not retrieve cluster status. The cluster may still be initializing.${NC}"
    echo -e "Run: ${BLUE}vagrant ssh controlplane -c 'kubectl get nodes'${NC} to check manually"
fi

cat << 'EOF'

=== Next Steps ===
1. SSH into control plane: vagrant ssh controlplane
2. Verify cluster: kubectl get nodes
3. Deploy a test app: kubectl create deployment nginx --image=nginx

Other useful commands:
  - List all VMs: vagrant status
  - SSH to worker1: vagrant ssh worker1
  - Destroy cluster: vagrant destroy -f
  - Rebuild cluster: vagrant destroy -f && vagrant up

Copy kubeconfig to your host (optional):
  vagrant ssh controlplane -c 'cat ~/.kube/config' > ~/.kube/k8s-vagrant-config
  export KUBECONFIG=~/.kube/k8s-vagrant-config
EOF