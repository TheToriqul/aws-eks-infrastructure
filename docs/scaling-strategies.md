# File: docs/scaling-strategies.md

# Node Group Scaling Strategies

## Instance Type Selection

### General Purpose Workloads
- **Primary**: t3.medium, t3a.medium
- **Secondary**: t3.large, t3a.large
- **Use Case**: Web applications, small-to-medium databases, dev/test environments

### Compute Optimized Workloads
- **Primary**: c5.large, c5a.large
- **Secondary**: c5.xlarge, c5a.xlarge
- **Use Case**: Batch processing, distributed analytics, game servers

### Memory Optimized Workloads
- **Primary**: r5.large, r5a.large
- **Secondary**: r5.xlarge, r5a.xlarge
- **Use Case**: In-memory databases, real-time big data analytics

## Scaling Policies

### Horizontal Pod Autoscaler (HPA)
- Configure HPA to scale based on CPU utilization (target: 70%)
- For memory-intensive applications, use memory utilization metrics
- Set appropriate min/max replica counts based on environment:
  - Dev: min=1, max=3
  - Staging: min=2, max=5
  - Production: min=3, max=10+

### Cluster Autoscaler
- Configure scale-up threshold at 80% resource utilization
- Set scale-down threshold at 40% resource utilization
- Implement scale-down delay of 10 minutes to prevent thrashing
- Use mixed instance types for better availability and cost optimization

## Cost Optimization Guidelines

### Spot Instance Strategy
- Use spot instances for:
  - Batch processing workloads
  - Stateless applications
  - Dev/test environments
  - Non-critical components
- Avoid spot instances for:
  - Stateful applications with no replication
  - Critical production services
  - Services requiring consistent performance

### Resource Allocation
- Set appropriate resource requests and limits for all containers
- Avoid over-provisioning; start small and scale up as needed
- Consider implementing node taints for specialized workloads

### Scaling Schedule
- Implement scheduled scaling for predictable workload patterns:
  - Scale down dev/test environments during non-working hours
  - Scale up before expected traffic peaks
  - Scale down after peak hours

### Cost Monitoring and Optimization
- Use AWS Cost Explorer and CloudWatch for monitoring
- Implement tagging strategy for cost allocation
- Review and adjust node groups monthly based on utilization metrics
- Consider using Savings Plans or Reserved Instances for stable workloads

## Node Group Strategy

| Workload Type | Instance Types | Scaling Strategy | Spot Usage |
|---------------|----------------|------------------|------------|
| Critical | on-demand: m5.large, m5.xlarge | Moderate scaling (min=2) | No |
| Standard | mixed: t3.medium, t3.large | Aggressive scaling | Partial (30-50%) |
| Batch/Dev | spot: various sizes | Very aggressive scaling | Maximum (80-100%) |