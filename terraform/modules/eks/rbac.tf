# File: terraform/modules/eks/rbac.tf

# Create Admin Role
resource "aws_iam_role" "eks_admin" {
  name = "${var.project_name}-${var.environment}-eks-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# Create Developer Role with Limited Access
resource "aws_iam_role" "eks_developer" {
  name = "${var.project_name}-${var.environment}-eks-developer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# EKS RBAC ConfigMap for AWS IAM roles
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_admin.arn
        username = "admin"
        groups   = ["system:masters"]
      },
      {
        rolearn  = aws_iam_role.eks_developer.arn
        username = "developer"
        groups   = ["developer"]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}