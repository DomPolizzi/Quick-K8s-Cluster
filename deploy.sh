#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Kubernetes Cluster Deployment Script ===${NC}\n"

# Check if Vagrant is installed
if ! command -v vagrant &> /dev/null; then
    echo -e "${RED}Error: Vagrant is not installed${NC}"
    echo -e "Please run ${GREEN}./install-prereqs.sh${NC} first"
    exit 1
fi

# Check if vagrant-libvirt plugin is installed
if ! vagrant plugin list | grep -q vagrant-libvirt; then
    echo -e "${RED}Error: vagrant-libvirt plugin is not installed${NC}"
    echo -e "Please run ${GREEN}./install-prereqs.sh${NC} first"
    exit 1
fi

# Check if user is in libvirt group
if ! groups | grep -q libvirt; then
    echo -e "${RED}Error: Current user is not in the 'libvirt' group${NC}"
    echo -e "Please log out and log back in after running ${GREEN}./install-prereqs.sh${NC}"
    exit 1
fi

echo -e "${BLUE}This will create a Kubernetes cluster with:${NC}"
echo -e "  - 1 control plane node (2 CPU, 2GB RAM) - IP: 192.168.56.10"
echo -e "  - 2 worker nodes (2 CPU, 2GB RAM each) - IPs: 192.168.56.11-12"
echo -e "  - Kubernetes v1.33.x with Calico CNI and CoreDNS"
echo ""

# Ask for confirmation
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Clean up any existing join-command.sh from previous runs
rm -f join-command.sh

echo -e "\n${YELLOW}Starting cluster deployment...${NC}"
echo -e "This will take 10-15 minutes depending on your internet connection.\n"

# Start the cluster
vagrant up

echo -e "\n${GREEN}=== Cluster Deployment Complete! ===${NC}\n"

echo -e "${BLUE}Cluster Information:${NC}"
vagrant ssh controlplane -c "kubectl get nodes -o wide"

echo -e "\n${BLUE}System Pods:${NC}"
vagrant ssh controlplane -c "kubectl get pods -A"

echo -e "\n${GREEN}=== Next Steps ===${NC}"
echo -e "1. SSH into control plane: ${YELLOW}vagrant ssh controlplane${NC}"
echo -e "2. Verify cluster: ${YELLOW}kubectl get nodes${NC}"
echo -e "3. Deploy a test app: ${YELLOW}kubectl create deployment nginx --image=nginx${NC}"
echo -e "\n${GREEN}Other useful commands:${NC}"
echo -e "  - List all VMs: ${YELLOW}vagrant status${NC}"
echo -e "  - SSH to worker1: ${YELLOW}vagrant ssh worker1${NC}"
echo -e "  - Destroy cluster: ${YELLOW}vagrant destroy -f${NC}"
echo -e "  - Rebuild cluster: ${YELLOW}vagrant destroy -f && vagrant up${NC}"
echo -e "\n${BLUE}Copy kubeconfig to your host (optional):${NC}"
echo -e "  ${YELLOW}vagrant ssh controlplane -c 'cat ~/.kube/config' > ~/.kube/k8s-vagrant-config${NC}"
echo -e "  ${YELLOW}export KUBECONFIG=~/.kube/k8s-vagrant-config${NC}"
