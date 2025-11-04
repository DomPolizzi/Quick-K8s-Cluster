#!/bin/bash
set -euo pipefail

CONTROL_PLANE_IP=$1

echo "=== Joining Worker Node to Cluster ==="

echo "[1/2] Waiting for join command from control plane..."
MAX_RETRIES=30
RETRY_COUNT=0

# Wait for HTTP server and fetch join command
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "Attempting to fetch join command... (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"

  # Try to download join command via HTTP
  if curl -sf http://${CONTROL_PLANE_IP}:8000/join-command.sh -o /tmp/join-command.sh 2>/dev/null; then
    if [ -s /tmp/join-command.sh ] && grep -q "kubeadm join" /tmp/join-command.sh; then
      echo "Successfully retrieved join command from control plane"
      break
    fi
  fi

  sleep 10
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ ! -f /tmp/join-command.sh ] || [ ! -s /tmp/join-command.sh ]; then
  echo "Error: Join command not found after $MAX_RETRIES attempts"
  exit 1
fi

# Join the cluster
echo "[2/2] Joining the cluster..."
sudo bash /tmp/join-command.sh

echo "=== Worker Node Joined Successfully ==="
echo "Note: Run 'vagrant ssh controlplane' and then 'kubectl get nodes' to verify"
