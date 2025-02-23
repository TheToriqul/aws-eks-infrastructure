# File: terraform/modules/monitoring/main.tf

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Container Insights Configuration
resource "aws_eks_addon" "container_insights" {
  cluster_name = var.cluster_name
  addon_name   = "amazon-cloudwatch-observability"
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for CloudWatch Metrics
resource "aws_iam_policy" "cloudwatch_metrics" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-metrics"
  description = "IAM policy for CloudWatch metrics collection"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

