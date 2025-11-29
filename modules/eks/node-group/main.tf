# 1. EKS Node IAM Role
resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-${var.node_group_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  tags = var.common_tags
}

# 2. Attach required policies to the Node Role
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_ssm" {
  count      = var.enable_ssm ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node.name
}

# 3. Launch Template (for Security Best Practices)
resource "aws_launch_template" "eks_node" {
  name_prefix = "${var.cluster_name}-${var.node_group_name}"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.disk_size
      volume_type = "gp3" # Default to gp3
      encrypted   = true  # (Security) Encrypt EBS volume
    }
  }

  # (Security) Force IMDSv2 (Instance Metadata Service v2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.common_tags
  }
  
  tags = var.common_tags
}

# 4. EKS Managed Node Group (MNG)
resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.subnet_ids # (Should be Private Subnets)
  version         = var.cluster_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # (Operations) Rolling update strategy
  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  instance_types = var.instance_types
  capacity_type  = var.capacity_type

  # (Security) Use the Launch Template created above
  launch_template {
    id      = aws_launch_template.eks_node.id
    version = aws_launch_template.eks_node.latest_version
  }

  labels = var.kubernetes_labels

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-${var.node_group_name}"
    }
  )

  # (Operations) Allow Cluster Autoscaler to manage 'desired_size'
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}