# File: terraform/modules/spot-instances/main.tf

resource "aws_eks_node_group" "spot" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}-${var.environment}-spot"
  node_role_arn   = aws_iam_role.spot_node_group.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  capacity_type  = "SPOT"
  instance_types = var.instance_types

  labels = {
    lifecycle = "Ec2Spot"
    type     = "spot-worker"
  }

  taint {
    key    = "spotInstance"
    value  = "true"
    effect = "PreferNoSchedule"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-spot"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# IAM Role for Spot Node Group
resource "aws_iam_role" "spot_node_group" {
  name = "${var.project_name}-${var.environment}-spot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "spot_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.spot_node_group.name
}

resource "aws_iam_role_policy_attachment" "spot_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.spot_node_group.name
}

resource "aws_iam_role_policy_attachment" "spot_ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.spot_node_group.name
}

# Spot Fleet AutoScaling Policy
resource "aws_iam_policy" "spot_autoscaling" {
  name = "${var.project_name}-${var.environment}-spot-autoscaling"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "spot_autoscaling" {
  policy_arn = aws_iam_policy.spot_autoscaling.arn
  role       = aws_iam_role.spot_node_group.name
}