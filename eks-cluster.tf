locals {
  standard_tags_asg_eks = concat(
    local.standard_tags_asg,
    list(
      {
        "key"                 = "k8s.io/cluster-autoscaler/enabled",
        "value"               = "true",
        "propagate_at_launch" = "false"
      },
      {
        "key"                 = "k8s.io/cluster-autoscaler/${local.env}",
        "value"               = "true",
        "propagate_at_launch" = "false"
      }
    )
  )
}

module "eks" {
  source                                             = "terraform-aws-modules/eks/aws"
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

  workers_group_defaults = {
    root_volume_type = "gp3"
  }

  worker_groups = [
    {
      instance_type = local.config.eks_worker_instance_type
      asg_max_size  = local.config.eks_worker_max_count
      tags          = local.standard_tags_asg_eks
    }
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"
  addon_version     = "v1.9.0-eksbuild.1"

  tags = local.standard_tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
  addon_version     = "v1.21.2-eksbuild.2"

  tags = local.standard_tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"
  addon_version     = "v1.8.4-eksbuild.1"

  tags = local.standard_tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
