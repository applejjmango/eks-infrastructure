# EKS Infrastructure Runbook

## Operational Procedures

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- kubectl installed
- Appropriate AWS IAM permissions

### Initial Setup

1. Configure S3 backend for Terraform state:
   ```hcl
   backend "s3" {
     bucket = "your-terraform-state-bucket"
     key    = "dev/network/terraform.tfstate"
     region = "us-east-1"
   }
   ```

2. Set environment variables:
   ```bash
   export AWS_REGION=us-east-1
   export AWS_PROFILE=your-profile
   ```

### Deployment

#### Deploy All Components

```bash
./scripts/deploy.sh dev all
```

#### Deploy Individual Components

```bash
# Network
./scripts/deploy.sh dev network

# EKS Cluster
./scripts/deploy.sh dev eks

# Addons
./scripts/deploy.sh dev addons

# Applications
./scripts/deploy.sh dev applications
```

### Destruction

#### Destroy All Components (Reverse Order)

```bash
./scripts/destroy.sh dev all
```

#### Destroy Individual Components

```bash
./scripts/destroy.sh dev applications
```

**Warning**: Destroy operations are irreversible. Always backup state before destroying.

### State Backup

```bash
./scripts/backup-state.sh dev your-terraform-state-bucket
```

### Common Operations

#### Update EKS Cluster

```bash
cd environments/dev/02-eks
terraform init
terraform plan
terraform apply
```

#### Scale Node Groups

Edit `environments/dev/02-eks/variables.tf` or use `terraform.tfvars`:

```hcl
desired_size = 4
max_size     = 8
min_size     = 2
```

Then apply:
```bash
cd environments/dev/02-eks
terraform apply
```

#### Add New Addon

1. Create module in `modules/addons/`
2. Add module call in `environments/dev/03-addons/main.tf`
3. Apply changes:
   ```bash
   cd environments/dev/03-addons
   terraform init
   terraform plan
   terraform apply
   ```

### Troubleshooting

#### EKS Cluster Not Accessible

1. Check security group rules
2. Verify endpoint access settings
3. Check IAM roles and policies

#### Node Group Not Joining

1. Check node role ARN
2. Verify subnet associations
3. Check node group status:
   ```bash
   aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name>
   ```

#### Addon Not Working

1. Check IRSA role ARN
2. Verify service account annotations
3. Check pod logs:
   ```bash
   kubectl logs -n kube-system <pod-name>
   ```

### Monitoring

#### Cluster Status

```bash
aws eks describe-cluster --name <cluster-name>
```

#### Node Status

```bash
kubectl get nodes
```

#### Pod Status

```bash
kubectl get pods -A
```

### Security Best Practices

1. **Enable Encryption**: Always enable EBS encryption and KMS for secrets
2. **Least Privilege**: Use IRSA for service accounts instead of node IAM roles
3. **Network Isolation**: Deploy sensitive workloads in private subnets
4. **Regular Updates**: Keep Kubernetes and addons updated
5. **Audit Logging**: Enable CloudWatch logging for EKS control plane

### Emergency Procedures

#### Cluster Unavailable

1. Check CloudWatch logs
2. Verify VPC and subnet configurations
3. Check security group rules
4. Contact AWS Support if needed

#### Data Loss Prevention

1. Regular state backups
2. EBS volume snapshots
3. Kubernetes backup solutions (Velero)

### Contact Information

- **Infrastructure Team**: [your-team-email]
- **On-Call**: [on-call-number]
- **Documentation**: [docs-url]

