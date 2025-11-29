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
# Tags
# ============================================
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}