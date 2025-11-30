# ============================================
# Addons Layer Variables
# ============================================

# ============================================
# General Variables
# ============================================
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "playdevops"
}

variable "development_division" {
  description = "Development Division"
  type        = string
  default     = "Infra"
}

# ============================================
# EBS CSI Driver Variables
# ============================================
variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI Driver add-on"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_addon_version" {
  description = "EBS CSI Driver add-on version (leave empty for latest)"
  type        = string
  default     = ""
}

variable "ebs_csi_driver_resolve_conflicts_on_create" {
  description = "How to resolve conflicts (OVERWRITE or NONE)"
  type        = string
  default     = "OVERWRITE"
}

variable "ebs_csi_driver_use_aws_managed_policy" {
  description = "Use AWS managed IAM policy"
  type        = bool
  default     = false
}

# ============================================
# Storage Configuration
# ============================================
variable "storage_class_name" {
  description = "Storage class name for EBS volumes"
  type        = string
  default     = "ebs-sc"
}

variable "pvc_storage_size" {
  description = "PVC storage size"
  type        = string
  default     = "4Gi"
}

# ============================================
# MySQL Configuration
# ============================================
variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  default     = "dbpassword11"
  sensitive   = true
}

variable "mysql_image" {
  description = "MySQL container image"
  type        = string
  default     = "mysql:5.6"
}

# ============================================
# WebApp Configuration
# ============================================
variable "webapp_replicas" {
  description = "Number of webapp replicas"
  type        = number
  default     = 1
}

variable "webapp_image" {
  description = "WebApp container image"
  type        = string
  default     = "stacksimplify/kube-usermanagement-microservice:1.0.0"
}

# ============================================
# Service Configuration
# ============================================
variable "enable_loadbalancer" {
  description = "Enable LoadBalancer service"
  type        = bool
  default     = true
}

variable "enable_nodeport" {
  description = "Enable NodePort service"
  type        = bool
  default     = false
}

variable "nodeport_port" {
  description = "NodePort port number"
  type        = number
  default     = 31280
}

# ============================================
# Tags
# ============================================
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}