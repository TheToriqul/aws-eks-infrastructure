# File: terraform/modules/node-groups/mixed-instances.tf

resource "aws_eks_node_group" "mixed" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}-${var.environment}-mixed"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.mixed_desired_size
    max_size     = var.mixed_max_size
    min_size     = var.mixed_min_size
  }

  instance_types = var.mixed_instance_types

  labels = {
    nodegroup = "mixed"
    environment = var.environment
  }

  # Use launch template for advanced configuration
  launch_template {
    id      = aws_launch_template.mixed.id
    version = aws_launch_template.mixed.latest_version
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-mixed"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Ensure proper IAM role creation before node group
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}

# Launch template for mixed instance node group
resource "aws_launch_template" "mixed" {
  name = "${var.project_name}-${var.environment}-mixed-lt"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-mixed-node"
      Environment = var.environment
    }
  }

  # Custom user data for node bootstrap
  user_data = base64encode(templatefile("${path.module}/templates/userdata.tpl", {
    cluster_name = var.cluster_name,
    environment  = var.environment,
    node_labels  = "nodegroup=mixed,environment=${var.environment}"
  }))

  lifecycle {
    create_before_destroy = true
  }
}