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
    }
    default = {
      eks_worker_instance_type = "m5.large"
      eks_worker_max_count     = 5
      cluster_version          = 1.21
    }
  }

  config = merge(local.env_config["default"], lookup(local.env_config, terraform.workspace, {}))

  standard_tags = {
    "env"         = local.env
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
