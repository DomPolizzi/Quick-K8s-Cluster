#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Installing Prerequisites for Kubernetes Vagrant Cluster ===${NC}\n"

# Check if running on Debian-based system
if [ ! -f /etc/debian_version ]; then
    echo -e "${RED}Error: This script is designed for Debian-based systems${NC}"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Please run this script as a regular user with sudo privileges${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Updating package lists...${NC}"
sudo apt update

echo -e "\n${YELLOW}[2/5] Installing required packages...${NC}"
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virtinst \
    virt-manager \
    cpu-checker \
    libguestfs-tools \
    libosinfo-bin

echo -e "\n${YELLOW}[3/5] Adding user to libvirt groups...${NC}"
sudo usermod -aG libvirt,kvm $USER

echo -e "\n${YELLOW}[4/5] Installing Vagrant...${NC}"

# Check if Vagrant is installed via Homebrew (incompatible with vagrant-libvirt)
if command -v brew &> /dev/null && brew list vagrant &>/dev/null 2>&1; then
    echo "Removing Homebrew Vagrant (incompatible with vagrant-libvirt)..."
    brew uninstall vagrant
    rm -rf ~/.vagrant.d
fi

if command -v vagrant &> /dev/null && dpkg -l | grep -q "^ii.*vagrant"; then
    echo "Official Vagrant is already installed: $(vagrant --version)"
else
    # Add HashiCorp official repository
    #echo "Adding HashiCorp repository..."
    #wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    # Detect codename (works for both Debian and Ubuntu)
    #CODENAME=$(grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release || lsb_release -cs)
    #echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Install Vagrant from HashiCorp repository
    sudo apt update
    sudo apt install -y vagrant

    echo "Vagrant installed: $(vagrant --version)"
fi

echo -e "\n${YELLOW}[5/5] Installing Vagrant libvirt plugin...${NC}"
if vagrant plugin list | grep -q vagrant-libvirt; then
    echo "vagrant-libvirt plugin is already installed"
else
    # Install dependencies for vagrant-libvirt plugin
    # Note: We need libc6-dev for stdio.h and other C standard library headers
    sudo apt install -y \
        ruby-dev \
        libvirt-dev \
        build-essential \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        libc6-dev \
        gcc \
        make

    # Use Vagrant's embedded Ruby to install the plugin to avoid conflicts
    vagrant plugin install vagrant-libvirt
    echo "vagrant-libvirt plugin installed successfully"
fi

echo -e "\n${GREEN}=== Prerequisites Installation Complete! ===${NC}"
echo -e "\n${YELLOW}IMPORTANT:${NC} You need to log out and log back in for group changes to take effect."
echo -e "After logging back in, verify with: ${GREEN}groups${NC} (should show 'libvirt' and 'kvm')"
echo -e "\nThen you can run: ${GREEN}./deploy.sh${NC} to create your cluster"
