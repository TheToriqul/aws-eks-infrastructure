# File: terraform/modules/eks/audit.tf

# CloudWatch Log Group for Audit Logs
resource "aws_cloudwatch_log_group" "eks_audit" {
  name              = "/aws/eks/${var.project_name}-${var.environment}/audit"
  retention_in_days = 90

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Audit Logging
resource "aws_iam_policy" "eks_audit" {
  name        = "${var.project_name}-${var.environment}-eks-audit"
  description = "IAM policy for EKS audit logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.eks_audit.arn}:*"
        ]
      }
    ]
  })
}

# Attach audit policy to cluster role
resource "aws_iam_role_policy_attachment" "eks_audit" {
  policy_arn = aws_iam_policy.eks_audit.arn
  role       = aws_iam_role.eks_cluster.name
}