variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version of the cluster (for node sync)"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS Node Group (e.g., 'general-purpose')"
  type        = string
}

variable "subnet_ids" {
  description = "List of Private Subnet IDs where nodes will be deployed"
  type        = list(string)
}

# Scaling
variable "desired_size" {
  description = "Desired number of nodes (managed by Cluster Autoscaler)"
  type        = number
  default     = 2
}
variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}
variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

# Instance
variable "instance_types" {
  description = "List of EC2 instance types for the nodes"
  type        = list(string)
  default     = ["t3.medium"]
}
variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}
variable "disk_size" {
  description = "EBS root volume size (in GB)"
  type        = number
  default     = 20
}

# Advanced
variable "enable_ssm" {
  description = "Flag to attach SSM policy to nodes (for debugging)"
  type        = bool
  default     = true
}
variable "max_unavailable_percentage" {
  description = "Max unavailable nodes percentage during rolling updates"
  type        = number
  default     = 33 # 33%
}

# Kubernetes
variable "kubernetes_labels" {
  description = "Map of Kubernetes labels to apply to the nodes"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Map of common tags"
  type        = map(string)
  default     = {}
}
