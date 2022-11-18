locals {
  standard_tags_asg_eks = concat(
    local.standard_tags_asg,
    [{
      "key"                 = "k8s.io/cluster-autoscaler/enabled",
      "value"               = "true",
      "propagate_at_launch" = "false"
      },
      {
        "key"                 = "k8s.io/cluster-autoscaler/${local.env}",
        "value"               = "true",
        "propagate_at_launch" = "false"
    }]
  )
}

module "eks" {
  source                                             = "terraform-aws-modules/eks/aws"
  version                                            = "17.24.0"
  cluster_name                                       = local.env
  cluster_version                                    = local.config.cluster_version
  vpc_id                                             = module.vpc.vpc_id
  subnets                                            = module.vpc.private_subnets
  write_kubeconfig                                   = false
  cluster_endpoint_private_access                    = true
  cluster_endpoint_public_access                     = true
  worker_create_security_group                       = true
  worker_create_cluster_primary_security_group_rules = true
  enable_irsa                                        = true
  tags                                               = local.standard_tags

  node_groups_defaults = {
    create_launch_template = true
    ami_type               = local.config.ami_type
    disk_type              = local.config.disk_type
    disk_size              = local.config.disk_size
  }

  node_groups = {
    apps = {
      version          = local.config.cluster_version
      desired_capacity = local.config.desired_capacity
      max_capacity     = local.config.max_capacity
      min_capacity     = local.config.min_capacity

      instance_types = [local.config.apps_instance_type]
      capacity_type  = local.config.capacity_type
      k8s_labels     = local.standard_tags

      update_config = {
        max_unavailable_percentage = local.config.max_unavailable_percentage # or set `max_unavailable`
      }
    }
    aenodes = {
      version          = local.config.cluster_version
      desired_capacity = local.config.desired_capacity
      max_capacity     = local.config.max_capacity
      min_capacity     = local.config.min_capacity

      instance_types = [local.config.aenodes_instance_type]
      capacity_type  = local.config.capacity_type
      k8s_labels     = local.standard_tags
      k8s_labels     = merge(local.standard_tags, try(local.config.aenode_tags, {}))

      taints = try(local.config.aenode_taints, [])

      update_config = {
        max_unavailable_percentage = local.config.max_unavailable_percentage # or set `max_unavailable`
      }
    }
  }

  map_roles = [
    {
      rolearn  = aws_iam_role.cluster_admin.arn
      username = "cluster-admin"
      groups   = ["system:masters"]
    }
  ]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "aws-ebs-csi-driver"
  resolve_conflicts = "OVERWRITE"
  addon_version     = "v1.10.0-eksbuild.1"

  tags = local.standard_tags
}


resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"
  addon_version     = "v1.12.0-eksbuild.1"

  tags = local.standard_tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
  addon_version     = "v1.23.8-eksbuild.2"

  tags = local.standard_tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"
  addon_version     = "v1.8.7-eksbuild.3"

  tags = local.standard_tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "--region",
      "eu-central-1",
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_id,
      "--role",
      aws_iam_role.cluster_admin.arn
    ]
  }
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
