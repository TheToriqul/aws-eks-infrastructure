# File: scripts/deployment/validate-cluster.sh

#!/bin/bash
set -e

echo "=== Starting EKS Cluster Validation ==="

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1"
        exit 1
    fi
}

# Check AWS CLI configuration
echo "1. Checking AWS CLI configuration..."
aws sts get-caller-identity > /dev/null 2>&1
check_status "AWS CLI configuration"

# Check kubectl configuration
echo "2. Checking kubectl configuration..."
kubectl cluster-info > /dev/null 2>&1
check_status "Kubectl configuration"

# Validate EKS cluster status
echo "3. Validating EKS cluster status..."
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.status' --output text)
if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
    echo "✅ EKS cluster is active"
else
    echo "❌ EKS cluster status: $CLUSTER_STATUS"
    exit 1
fi

# Check node groups
echo "4. Checking node groups..."
kubectl get nodes -o wide
check_status "Node groups validation"

# Validate availability zones
echo "5. Checking multi-AZ deployment..."
NODE_AZS=$(kubectl get nodes -o json | jq -r '.items[].metadata.labels["topology.kubernetes.io/zone"]' | sort | uniq | wc -l)
if [ "$NODE_AZS" -ge 3 ]; then
    echo "✅ Nodes distributed across $NODE_AZS availability zones"
else
    echo "⚠️ Nodes only in $NODE_AZS availability zones - check configuration"
fi

# Test spot instance configuration
echo "6. Validating spot instances..."
SPOT_NODES=$(kubectl get nodes -l capacity-type=spot --no-headers 2>/dev/null | wc -l)
echo "Found $SPOT_NODES spot instances"
check_status "Spot instance validation"

# Test autoscaling configuration
echo "7. Validating cluster autoscaler..."
kubectl get deployment cluster-autoscaler -n kube-system &>/dev/null
check_status "Cluster autoscaler deployment"

# Check monitoring setup
echo "8. Validating monitoring configuration..."
kubectl get pods -n amazon-cloudwatch --no-headers 2>/dev/null | wc -l
check_status "CloudWatch monitoring pods"

echo "=== Validation Complete ==="