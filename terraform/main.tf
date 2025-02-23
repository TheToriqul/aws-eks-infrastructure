# File: terraform/main.tf

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "tls" {}

module "vpc" {
  source = "./modules/vpc"

  environment        = var.environment
  project_name      = var.project_name
  availability_zones = var.availability_zones
  cluster_name      = "${var.project_name}-${var.environment}"  # This matches your EKS cluster naming
  additional_tags   = var.additional_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name = var.project_name
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  enable_irsa = true
}

module "node_groups" {
  source = "./modules/node-groups"

  project_name       = var.project_name
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  private_subnet_ids = module.vpc.private_subnet_ids
  
  depends_on = [
    module.eks
  ]
}

module "spot_instances" {
  source = "./modules/spot-instances"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = module.eks.cluster_name
  subnet_ids   = module.vpc.private_subnet_ids

  depends_on = [
    module.eks,
    module.node_groups
  ]
}

