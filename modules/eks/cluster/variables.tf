# ============================================
# EKS Cluster Module Variables
# ============================================

# ============================================
# General
# ============================================
variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

# ============================================
# Network
# ============================================
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# ============================================
# Cluster Configuration
# ============================================
variable "cluster_service_ipv4_cidr" {
  description = "Service IPv4 CIDR for the cluster"
  type        = string
  default     = "172.20.0.0/16"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks for public access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ============================================
# OIDC Provider
# ============================================
variable "eks_oidc_root_ca_thumbprint" {
  description = "Thumbprint of Root CA for EKS OIDC"
  type        = string
  default     = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
}

# ============================================
# Node Group
# ============================================
variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "node_group_ami_type" {
  description = "AMI type for EKS nodes"
  type        = string
  default     = "AL2_x86_64"
}

variable "node_group_capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "node_group_instance_types" {
  description = "List of instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_group_max_unavailable" {
  description = "Max unavailable nodes during update"
  type        = number
  default     = 1
}

variable "node_group_keypair" {
  description = "EC2 Key Pair for SSH access to nodes"
  type        = string
}

variable "node_group_subnet_ids" {
  description = "Subnet IDs for node group (defaults to public_subnet_ids)"
  type        = list(string)
  default     = []
}

# ============================================
# Logging
# ============================================
variable "cluster_enabled_log_types" {
  description = "List of control plane logging types"
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "cluster_log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ============================================
# Tags
# ============================================
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}