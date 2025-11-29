# EKS Infrastructure Architecture

## Overview

This document describes the architecture of the EKS infrastructure managed by Terraform.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                              │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  VPC (10.0.0.0/16)                    │   │
│  │                                                        │   │
│  │  ┌──────────────┐        ┌──────────────┐             │   │
│  │  │ Public       │        │ Private      │             │   │
│  │  │ Subnets      │        │ Subnets      │             │   │
│  │  │              │        │              │             │   │
│  │  │ ┌──────────┐ │        │ ┌──────────┐ │             │   │
│  │  │ │  NAT GW  │ │        │ │  EKS     │ │             │   │
│  │  │ │          │ │        │ │  Cluster │ │             │   │
│  │  │ └──────────┘ │        │ │          │ │             │   │
│  │  │              │        │ │ ┌──────┐ │             │   │
│  │  │ ┌──────────┐ │        │ │ │Nodes │ │             │   │
│  │  │ │  IGW     │ │        │ │ └──────┘ │             │   │
│  │  │ │          │ │        │ │          │             │   │
│  │  │ └──────────┘ │        │ └──────────┘             │   │
│  │  │              │        │              │             │   │
│  │  │ ┌──────────┐ │        │              │             │   │
│  │  │ │ Bastion  │ │        │              │             │   │
│  │  │ │ Host     │ │        │              │             │   │
│  │  │ └──────────┘ │        │              │             │   │
│  │  └──────────────┘        └──────────────┘             │   │
│  │                                                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  IAM Roles                            │   │
│  │  • EKS Cluster Role                                   │   │
│  │  • EKS Node Role                                      │   │
│  │  • IRSA Roles (for addons)                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  EKS Addons                           │   │
│  │  • AWS Load Balancer Controller                      │   │
│  │  • EBS CSI Driver                                     │   │
│  │  • External DNS                                       │   │
│  │  • Cluster Autoscaler                                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC
- **CIDR Block**: 10.0.0.0/16 (configurable)
- **Availability Zones**: 2+ (configurable)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

### Subnets
- **Public Subnets**: For Internet-facing resources (Bastion, NAT Gateway)
- **Private Subnets**: For EKS cluster and nodes

### Routing
- **Internet Gateway**: Attached to VPC for public internet access
- **NAT Gateways**: One per availability zone for private subnet outbound traffic

## Compute Architecture

### EKS Cluster
- **Kubernetes Version**: 1.28 (configurable)
- **Endpoint Access**: 
  - Private: Enabled
  - Public: Enabled (configurable CIDR blocks)

### Node Groups
- **Instance Types**: t3.medium (configurable)
- **Scaling**: Configurable min/max/desired size
- **Capacity Type**: On-Demand or Spot (configurable)

### Bastion Host
- **Instance Type**: t3.micro (configurable)
- **Purpose**: Secure access to private resources
- **Location**: Public subnet

## IAM Architecture

### Roles
1. **EKS Cluster Role**: For EKS control plane
2. **EKS Node Role**: For worker nodes
3. **IRSA Roles**: For service accounts (addons)

### Policies
- AWS managed policies for EKS
- Custom policies for addons (Load Balancer Controller, External DNS, etc.)

## Security

### Security Groups
1. **EKS Cluster SG**: Controls traffic to EKS control plane
2. **EKS Node SG**: Controls traffic to worker nodes
3. **Bastion SG**: Controls SSH access to bastion host

### Encryption
- **EBS Volumes**: Encrypted
- **Secrets**: Encrypted using KMS (configurable)

## Addons

### AWS Load Balancer Controller
- Manages Application Load Balancers (ALB) and Network Load Balancers (NLB)
- Creates Ingress resources automatically

### EBS CSI Driver
- Provides persistent volumes for EKS pods
- Supports volume expansion and encryption

### External DNS
- Automatically creates DNS records in Route53
- Works with Ingress resources

### Cluster Autoscaler
- Automatically scales node groups based on pod scheduling needs
- Integrates with AWS Auto Scaling Groups

## Deployment Flow

1. **Network**: Deploy VPC, subnets, NAT gateways
2. **EKS**: Deploy EKS cluster and node groups
3. **Addons**: Install EKS addons (controllers, drivers)
4. **Applications**: Deploy Kubernetes applications

## Environments

- **Dev**: Development environment
- **Staging**: Pre-production testing
- **Prod**: Production environment

Each environment is isolated with its own:
- VPC
- EKS Cluster
- Resource naming conventions
- Configuration values

