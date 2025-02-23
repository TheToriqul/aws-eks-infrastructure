# File: terraform/modules/monitoring/outputs.tf

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.eks.name
}

output "cloudwatch_metrics_policy_arn" {
  description = "ARN of the CloudWatch metrics IAM policy"
  value       = aws_iam_policy.cloudwatch_metrics.arn
}