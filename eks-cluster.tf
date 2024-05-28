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
  version                                            = "17.15.0"
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
    ebs_optimized          = true
  }

  node_groups = {
    apps = {
      version          = local.config.cluster_version
      desired_capacity = local.config.desired_capacity
      min_capacity     = local.config.min_capacity
      max_capacity     = local.config.max_capacity

      instance_types = local.config.apps_instance_types
      capacity_type  = local.config.capacity_type
      k8s_labels     = local.standard_tags

      subnets  = [module.vpc.private_subnets[0]]

      update_config = {
        max_unavailable_percentage = local.config.max_unavailable_percentage # or set `max_unavailable`
      }
    }

    apps2 = {
      version          = local.config.cluster_version
      desired_capacity = local.config.desired_capacity
      max_capacity     = local.config.max_capacity
      min_capacity     = local.config.min_capacity

      instance_types = local.config.apps_instance_types
      capacity_type  = local.config.capacity_type
      k8s_labels     = local.standard_tags

      subnets  = [module.vpc.private_subnets[1]]

      update_config = {
        max_unavailable_percentage = local.config.max_unavailable_percentage # or set `max_unavailable`
      }
    }

    apps3 = {
      version          = local.config.cluster_version
      desired_capacity = local.config.desired_capacity
      max_capacity     = local.config.max_capacity
      min_capacity     = local.config.min_capacity

      instance_types = local.config.apps_instance_types
      capacity_type  = local.config.capacity_type
      k8s_labels     = local.standard_tags

      subnets  = [module.vpc.private_subnets[2]]

      update_config = {
        max_unavailable_percentage = local.config.max_unavailable_percentage # or set `max_unavailable`
      }
    }

    # aenodes = {
    #   version          = local.config.cluster_version
    #   desired_capacity = local.config.aenodes_desired_capacity
    #   max_capacity     = local.config.aenodes_max_capacity
    #   min_capacity     = local.config.aenodes_min_capacity

    #   instance_types = [local.config.aenodes_instance_type]
    #   capacity_type  = local.config.capacity_type
    #   k8s_labels     = local.standard_tags
    #   k8s_labels     = merge(local.standard_tags, try(local.config.aenode_tags, {}))

    #   taints = try(local.config.aenode_taints, [])

    #   update_config = {
    #     max_unavailable_percentage = local.config.max_unavailable_percentage # or set `max_unavailable`
    #   }
    # }

  }

  map_roles = [
    {
      rolearn  = aws_iam_role.cluster_admin.arn
      username = "cluster-admin"
      groups   = ["system:masters"]
    }
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_version               = "v1.13.0-eksbuild.1"

  configuration_values = jsonencode({
    env = {
      # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  })

  tags = local.standard_tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_version               = "v1.23.8-eksbuild.2"

  tags = local.standard_tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_version               = "v1.8.7-eksbuild.6"

  tags = local.standard_tags
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_version               = "v1.19.0-eksbuild.2"

  service_account_role_arn    = module.aws-ebs-controller-role.iam_role_arn

  tags                        = local.standard_tags

  # configuration_values = jsonencode({
  #   resources = {
  #     limits = {
  #       cpu    = "20m"
  #       memory = "60Mi"
  #     }
  #     requests = {
  #       cpu    = "10m"
  #       memory = "40Mi"
  #     }
  #   }
  # })
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
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
