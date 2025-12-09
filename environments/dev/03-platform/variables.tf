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

variable "division" {
  description = "Organizational or technical division"
  type        = string
  default     = "CloudInfra"
}

# ============================================
# ACM & Route53 Variables (통합됨)
# ============================================
variable "acm_domain_name" {
  description = "ACM 인증서를 생성할 도메인 이름 (예: playdevops.click)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID (DNS 검증 및 ExternalDNS용)"
  type        = string
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
  description = "EBS CSI Driver add-on version"
  type        = string
  default     = ""
}

variable "ebs_csi_driver_resolve_conflicts_on_create" {
  description = "How to resolve conflicts"
  type        = string
  default     = "OVERWRITE"
}

variable "ebs_csi_driver_use_aws_managed_policy" {
  description = "Use AWS managed IAM policy"
  type        = bool
  default     = false
}

# ============================================
# AWS Load Balancer Controller Variables
# ============================================
variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "alb_controller_chart_version" {
  description = "Helm chart version"
  type        = string
  default     = ""
}

variable "alb_controller_image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
}

variable "alb_controller_ingress_class_name" {
  description = "Name of the Ingress Class"
  type        = string
  default     = "alb"
}

variable "alb_controller_is_default" {
  description = "Set as default Ingress Class"
  type        = bool
  default     = true
}

# ============================================
# ExternalDNS Variables
# ============================================
variable "enable_external_dns" {
  description = "Enable ExternalDNS add-on"
  type        = bool
  default     = true
}

variable "external_dns_chart_version" {
  description = "Helm chart version"
  type        = string
  default     = "1.14.5"
}

# [삭제됨] external_dns_hosted_zone_id는 hosted_zone_id로 통합되어 삭제했습니다.

variable "external_dns_domain_filters" {
  description = "List of domains for ExternalDNS to manage"
  type        = list(string)
  default     = ["playdevops.click"]
}

# ============================================
# Tags
# ============================================
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}