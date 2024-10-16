data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

resource "random_string" "id_suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  # use this variable as prefix for all resource names. This avoids conflicts with globally unique resources (all resources with a hostname)
  env       = "${terraform.workspace}-${random_string.id_suffix.result}"
  env_human = terraform.workspace

  env_config = {
    dev = {
      cluster_version            = "1.30"
      # Node group defaults
      ami_type                   = "AL2_x86_64"
      disk_type                  = "gp3"
      disk_size                  = 30
      cidr                       = "10.0.0.0/16"
      private_subnets            = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      public_subnets             = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
      # Node capacity per node group. 1 node group per AZ = 3 groups
      desired_capacity           = 1
      min_capacity               = 1
      max_capacity               = 3
      # use single instance type because of autoscaller and max-nodes limit
      apps_instance_types        = ["m7i.large"]
      capacity_type              = "SPOT"
      max_unavailable_percentage = 50
      # Nodes node group
      aenodes_instance_type      = "m7i.large"
      aenode_tags                = { "aenodes" = "yes" }
      aenode_taints              = [{ key = "aenodes", value = "yes", effect = "NO_SCHEDULE" }]
    }

    stg = {
      cluster_version            = "1.30"
      # Node group defaults
      ami_type                   = "AL2_x86_64"
      disk_type                  = "gp3"
      disk_size                  = 100
      cidr                       = "192.168.0.0/16"
      private_subnets            = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
      public_subnets             = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
      # Node capacity per node group. 1 node group per AZ = 3 groups
      desired_capacity           = 1
      min_capacity               = 1
      max_capacity               = 3
      # use single instance type because of autoscaller and max-nodes limit
      apps_instance_types        = ["m6i.large"]
      capacity_type              = "SPOT"
      max_unavailable_percentage = 50
      # Nodes node group
      aenodes_instance_type      = "m5.large"
      aenode_tags                = { "aenodes" = "yes" }
      aenode_taints              = [{ key = "aenodes", value = "yes", effect = "NO_SCHEDULE" }]
    }

    prd = {
      cluster_version            = "1.30"
      # Node group defaults
      ami_type                   = "AL2_x86_64"
      disk_type                  = "gp3"
      disk_size                  = 100
      cidr                       = "172.16.0.0/16"
      private_subnets            = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
      public_subnets             = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
      # Node capacity per node group. 1 node group per AZ = 3 groups
      desired_capacity           = 1
      min_capacity               = 1
      max_capacity               = 3
      # use single instance type because of autoscaller and max-nodes limit
      apps_instance_types        = ["m6i.large"]
      capacity_type              = "ON_DEMAND"
      max_unavailable_percentage = 30
      # Nodes node group
      aenodes_instance_type      = "m5.large"
      aenode_tags                = { "aenodes" = "yes" }
      aenode_taints              = [{ key = "aenodes", value = "yes", effect = "NO_SCHEDULE" }]
    }
  }

  config = merge(lookup(local.env_config, terraform.workspace, {}))

  standard_tags = {
    "env"         = local.env
    "role"        = "k8s"
    "project"     = "apps"
    "github-repo" = "terraform-aws-apps"
    "github-org"  = "aeternity"
  }

  standard_tags_asg = [for key in keys(local.standard_tags) : {
    key                 = key
    value               = lookup(local.standard_tags, key)
    propagate_at_launch = "true"
  }]

  tag_query = join(",\n", [for key in keys(local.standard_tags) : <<JSON
    {
      "Key": "${key}",
      "Values": ["${lookup(local.standard_tags, key)}"]
    }
  JSON
  ])
}
