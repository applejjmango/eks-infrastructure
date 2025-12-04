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
  description = "Organizational or technical division responsible for this infrastructure"
  type        = string
  default     = "CloudInfra"
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
  sensitive   = true
  default     = null
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
# AWS Load Balancer Controller Variables
# ============================================
variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "alb_controller_chart_version" {
  description = "Helm chart version for AWS Load Balancer Controller"
  type        = string
  default     = "" # Use latest
}

variable "alb_controller_image_repository" {
  description = "Docker image repository for AWS Load Balancer Controller (region-specific)"
  type        = string
  default     = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
}

variable "alb_controller_ingress_class_name" {
  description = "Name of the Ingress Class"
  type        = string
  default     = "alb"
}

variable "alb_controller_is_default" {
  description = "Set AWS Load Balancer Controller Ingress Class as default"
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
  description = "Helm chart version for ExternalDNS"
  type        = string
  default     = "1.14.5"
}

variable "external_dns_hosted_zone_id" {
  description = "Route53 Hosted Zone ID for ExternalDNS to manage"
  type        = string
}

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