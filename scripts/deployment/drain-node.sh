# File: scripts/deployment/drain-node.sh

#!/bin/bash
set -e

# Check if node name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <node-name>"
  exit 1
fi

NODE_NAME=$1
echo "Preparing to drain node: $NODE_NAME"

# Set cluster context
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --name $CLUSTER_NAME --region $(terraform output -raw aws_region)

# Check if the node exists
if ! kubectl get node $NODE_NAME &> /dev/null; then
  echo "Error: Node $NODE_NAME not found"
  exit 1
fi

# Cordon the node (mark as unschedulable)
echo "Cordoning node $NODE_NAME..."
kubectl cordon $NODE_NAME

# Drain the node (evict all pods safely)
echo "Draining node $NODE_NAME..."
kubectl drain $NODE_NAME \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --timeout=120s

echo "Node $NODE_NAME has been drained successfully"
echo "You can now safely terminate the node"

# Optionally, terminate the node via AWS CLI
read -p "Do you want to terminate this node? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Fetching instance ID for node $NODE_NAME..."
  INSTANCE_ID=$(kubectl get node $NODE_NAME -o jsonpath='{.spec.providerID}' | sed 's|^.*/||')
  
  echo "Terminating instance $INSTANCE_ID..."
  aws ec2 terminate-instances --instance-ids $INSTANCE_ID
  
  echo "Instance termination initiated. Removing node from Kubernetes..."
  kubectl delete node $NODE_NAME
  
  echo "Node $NODE_NAME has been removed from the cluster"
fi