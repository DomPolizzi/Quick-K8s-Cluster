#!/bin/bash
set -euo pipefail

CONTROL_PLANE_IP=$1

echo "=== Joining Worker Node to Cluster ==="

# Wait for join command to be available
echo "[1/2] Waiting for join command from control plane..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ ! -f /vagrant/join-command.sh ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "Waiting for join command... (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ ! -f /vagrant/join-command.sh ]; then
  echo "Error: Join command not found after $MAX_RETRIES attempts"
  exit 1
fi

# Join the cluster
echo "[2/2] Joining the cluster..."
sudo bash /vagrant/join-command.sh

echo "=== Worker Node Joined Successfully ==="
echo "Note: Run 'vagrant ssh controlplane' and then 'kubectl get nodes' to verify"
