# File: terraform/modules/spot-instances/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the spot instances"
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of spot instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of spot instances"
  type        = number
  default     = 5
}

variable "min_size" {
  description = "Minimum number of spot instances"
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "List of instance types for spot instances"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "t3a.medium", "t3a.large"]
}
