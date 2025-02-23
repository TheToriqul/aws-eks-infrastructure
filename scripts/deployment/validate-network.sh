# File: scripts/deployment/validate-network.sh

#!/bin/bash
set -e

echo "=== Starting Network Validation ==="

# Check VPC Configuration
echo "1. Validating VPC setup..."
VPC_ID=$(terraform output -raw vpc_id)
aws ec2 describe-vpcs --vpc-ids $VPC_ID > /dev/null 2>&1
check_status "VPC validation"

# Check Subnets
echo "2. Validating subnets..."
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' \
    --output table

# Check Route Tables
echo "3. Checking route tables..."
aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[*].Routes[*]' \
    --output table

# Check Security Groups
echo "4. Validating security groups..."
aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[*].[GroupName,GroupId]' \
    --output table

# Test Network Connectivity
echo "5. Testing network connectivity..."
kubectl run test-nginx --image=nginx
kubectl expose pod test-nginx --port=80 --type=LoadBalancer
sleep 30
kubectl get svc test-nginx

# Cleanup
kubectl delete svc test-nginx
kubectl delete pod test-nginx

echo "=== Network Validation Complete ==="