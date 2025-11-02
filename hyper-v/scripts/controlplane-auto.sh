#!/bin/bash
set -euo pipefail

echo "=== Initializing Kubernetes Control Plane ==="

# Auto-discover the primary IP address
echo "[0/5] Discovering IP address..."
CONTROL_PLANE_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)

if [ -z "$CONTROL_PLANE_IP" ]; then
    echo "ERROR: Could not determine IP address"
    exit 1
fi

echo "Using IP address: $CONTROL_PLANE_IP"

# Initialize the cluster
echo "[1/5] Running kubeadm init..."
sudo kubeadm init \
  --apiserver-advertise-address=$CONTROL_PLANE_IP \
  --pod-network-cidr=10.244.0.0/16 \
  --node-name=controlplane

# Set up kubeconfig for vagrant user
echo "[2/5] Setting up kubeconfig..."
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# Set up kubeconfig for root user (useful for sudo kubectl commands)
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Install Calico CNI
echo "[3/5] Installing Calico CNI..."
kubectl --kubeconfig=/home/vagrant/.kube/config apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Generate join command for workers
echo "[4/5] Generating join command for worker nodes..."
# Store join command in shared folder
sudo kubeadm token create --print-join-command > /vagrant/join-command.sh
chmod 644 /vagrant/join-command.sh

echo "Join command saved to /vagrant/join-command.sh"

# Wait for nodes to be ready
echo "[5/5] Waiting for control plane to be ready..."
kubectl --kubeconfig=/home/vagrant/.kube/config wait --for=condition=Ready node/controlplane --timeout=300s

echo "=== Control Plane Initialization Complete ==="
echo ""
echo "Control Plane IP: $CONTROL_PLANE_IP"
echo ""
echo "Cluster Status:"
kubectl --kubeconfig=/home/vagrant/.kube/config get nodes
echo ""
echo "System Pods:"
kubectl --kubeconfig=/home/vagrant/.kube/config get pods -n kube-system
