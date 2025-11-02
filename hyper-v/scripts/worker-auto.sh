#!/bin/bash
set -euo pipefail

echo "=== Joining Worker Node to Kubernetes Cluster ==="

# Wait for join command to be available
echo "[1/2] Waiting for join command from control plane..."
RETRIES=30
COUNT=0

while [ ! -f /vagrant/join-command.sh ] && [ $COUNT -lt $RETRIES ]; do
    echo "Waiting for join command... (attempt $((COUNT+1))/$RETRIES)"
    sleep 10
    COUNT=$((COUNT+1))
done

if [ ! -f /vagrant/join-command.sh ]; then
    echo "ERROR: Join command not found after $RETRIES attempts"
    echo "Please ensure the control plane has been initialized successfully"
    exit 1
fi

# Join the cluster
echo "[2/2] Joining the cluster..."
sudo bash /vagrant/join-command.sh

echo "=== Worker Node Join Complete ==="
