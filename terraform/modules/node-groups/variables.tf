# File: terraform/modules/node-groups/variables.tf

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

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS node group"
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}


variable "mixed_desired_size" {
  description = "Desired number of nodes in mixed instance group"
  type        = number
  default     = 2
}

variable "mixed_max_size" {
  description = "Maximum number of nodes in mixed instance group"
  type        = number
  default     = 5
}

variable "mixed_min_size" {
  description = "Minimum number of nodes in mixed instance group"
  type        = number
  default     = 1
}

variable "mixed_instance_types" {
  description = "List of instance types for mixed instance policy"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t3.large", "t3a.large"]
}

variable "disk_size" {
  description = "Node disk size in GB"
  type        = number
  default     = 20
}