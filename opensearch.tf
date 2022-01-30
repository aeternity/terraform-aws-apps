locals {
  cluster_name   = "opensearch-${terraform.workspace}"
  cluster_domain = "aepps.com"
}

data "aws_region" "current" {}

provider "elasticsearch" {
  url                   = "https://${local.cluster_name}.${local.cluster_domain}"
  aws_region            = data.aws_region.current.name
  elasticsearch_version = "7.10.2"
  healthcheck           = false
}

module "opensearch" {
  source          = "./terraform-aws-opensearch"
  cluster_name    = local.cluster_name
  cluster_domain  = local.cluster_domain
  cluster_version = "1.0"

  warm_instance_enabled   = var.warm_instance_enabled[terraform.workspace]
  master_instance_count   = var.master_instance_count[terraform.workspace]
  master_instance_enabled = var.master_instance_enabled[terraform.workspace]
  hot_instance_count      = var.hot_instance_count[terraform.workspace]
  availability_zones      = var.availability_zones[terraform.workspace]
  master_user_name        = "es-admin"
  master_user_password    = var.opensearch_master_user_password[terraform.workspace]
  ebs_enabled             = var.ebs_enabled[terraform.workspace]
  volume_size             = var.volume_size[terraform.workspace]
  hot_instance_type       = var.hot_instance_type[terraform.workspace]
}

resource "null_resource" "es_backend_role" {
  provisioner "local-exec" {
    command = <<EOT
        curl -sS -u "es-admin:${var.opensearch_master_user_password[terraform.workspace]}" \
        -X PATCH \
        https://opensearch-dev.aepps.com/_opendistro/_security/api/rolesmapping/all_access?pretty \
        -H 'Content-Type: application/json' \
        -d'
        [
          {
            "op": "add", "path": "/backend_roles", "value": ["${module.eks.cluster_iam_role_arn}"]
          }
        ]
        '
EOT
  }
}
