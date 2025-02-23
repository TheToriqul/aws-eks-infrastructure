# File: docs/testing/testing-runbook.md

# EKS Cluster Testing Runbook

## Prerequisites
- AWS CLI configured with appropriate permissions
- kubectl installed and configured
- Terraform installed
- jq installed for JSON parsing

## Testing Procedures

### 1. Initial Cluster Validation
```bash
./scripts/deployment/validate-cluster.sh
```

### 2. Manual Validation Steps

#### Network Connectivity Test
1. Deploy test pod:
```bash
kubectl run nginx-test --image=nginx
kubectl expose pod nginx-test --port=80 --type=LoadBalancer
```

2. Verify LoadBalancer creation:
```bash
kubectl get svc nginx-test
```

3. Test connectivity using the LoadBalancer DNS

#### High Availability Test
1. Monitor node distribution:
```bash
kubectl get nodes -o wide
```

2. Verify pods spread across nodes:
```bash
kubectl get pods -o wide --all-namespaces
```

#### Spot Instance Failover Test
1. Identify spot instances:
```bash
kubectl get nodes -l capacity-type=spot
```

2. Deploy test application with spot node affinity
3. Simulate spot interruption
4. Verify pod rescheduling

### 3. Load Testing
1. Deploy sample application
2. Generate load using hey or apache benchmark
3. Monitor autoscaling behavior

### 4. Recovery Testing
1. Test node failure scenarios
2. Verify pod rescheduling
3. Check system logs

## Common Issues and Solutions

### Node Group Issues
- Check AWS Auto Scaling Groups
- Verify IAM roles and policies
- Check security group configurations

### Networking Issues
- Verify VPC configurations
- Check route tables
- Validate security group rules

### Monitoring Issues
- Verify CloudWatch agent configuration
- Check IAM permissions
- Validate log group creation

## Testing Schedule
- Full validation: Weekly
- Basic health check: Daily
- Load testing: Monthly
- Recovery testing: Quarterly

## Reporting
Document all test results including:
- Test date and time
- Test type
- Results
- Any issues found
- Resolution steps taken