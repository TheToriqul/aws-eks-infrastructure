# File: terraform/modules/spot-instances/outputs.tf

output "node_group_arn" {
  description = "ARN of the spot node group"
  value       = aws_eks_node_group.spot.arn
}

output "node_group_id" {
  description = "ID of the spot node group"
  value       = aws_eks_node_group.spot.id
}

output "node_group_status" {
  description = "Status of the spot node group"
  value       = aws_eks_node_group.spot.status
}

output "autoscaling_group_name" {
  description = "Name of the AutoScaling Group for spot instances"
  value       = aws_eks_node_group.spot.resources[0].autoscaling_groups[0].name
}