locals {
  cluster_name   = "opensearch-${terraform.workspace}"
  cluster_domain = "aepps.com"
  es_linked_role = data.aws_iam_role.service_linked_role.id
}

data "aws_region" "current" {}

data "aws_iam_role" "service_linked_role" {
  name = "AWSServiceRoleForAmazonElasticsearchService"
}

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
  aws_iam_service_linked_role_es = local.es_linked_role
}

resource "null_resource" "es_backend_role_cluster" {
  provisioner "local-exec" {
    command = <<EOT
        curl -sS -u "es-admin:${var.opensearch_master_user_password[terraform.workspace]}" \
        -X PATCH \
        https://${local.cluster_name}.aepps.com/_opendistro/_security/api/rolesmapping/all_access?pretty \
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
  depends_on = [module.opensearch]
}

resource "null_resource" "es_backend_role_worker" {
  provisioner "local-exec" {
    command = <<EOT
        curl -sS -u "es-admin:${var.opensearch_master_user_password[terraform.workspace]}" \
        -X PATCH \
        https://${local.cluster_name}.aepps.com/_opendistro/_security/api/rolesmapping/all_access?pretty \
        -H 'Content-Type: application/json' \
        -d'
        [
          {
            "op": "add", "path": "/backend_roles", "value": ["${module.eks.worker_iam_role_arn}"]
          }
        ]
        '
EOT
  }
  depends_on = [module.opensearch, null_resource.es_backend_role_cluster]
}

resource "null_resource" "ism_rollover_index_templates" {
  provisioner "local-exec" {
    command = <<EOT
        curl -sS -u "es-admin:${var.opensearch_master_user_password[terraform.workspace]}" \
        -X PUT \
        https://${local.cluster_name}.aepps.com/_index_template/ism_rollover?pretty \
        -H 'Content-Type: application/json' \
        -d'
        {
          "index_patterns": ["fluent-bit*"],
          "template": {
          "settings": {
            "plugins.index_state_management.rollover_alias": "fluentbit"
          }
        }
        }
        '
EOT
  }
  depends_on = [module.opensearch]
}

resource "null_resource" "fluent_bit_index" {
  provisioner "local-exec" {
    command = <<EOT
        curl -sS -u "es-admin:${var.opensearch_master_user_password[terraform.workspace]}" \
        -X PUT \
        https://${local.cluster_name}.aepps.com/fluent-bit-000001 \
        -H 'Content-Type: application/json' \
        -d'
        {
          "aliases": {
            "fluentbit": {
              "is_write_index": true
            }
          }
        }
        '
EOT
  }
  depends_on = [null_resource.ism_rollover_index_templates]
}


resource "null_resource" "fluent_bit_rollover_policy" {
  provisioner "local-exec" {
    command = <<EOT
        curl -sS -u "es-admin:${var.opensearch_master_user_password[terraform.workspace]}" \
        -X PUT \
        https://${local.cluster_name}.aepps.com/_plugins/_ism/policies/fluent-bit-rollover-${local.cluster_name} \
        -H 'Content-Type: application/json' \
        -d'
        {
            "policy": {
                "policy_id": "rollover",
                "description": "A simple default policy that rollover and deletes old indicies.",
                "default_state": "rollover",
                "states": [
                    {
                        "name": "rollover",
                        "actions": [
                            {
                                "rollover": {
                                    "min_index_age": "1d"
                                }
                            }
                        ],
                        "transitions": [
                            {
                                "state_name": "delete",
                                "conditions": {
                                    "min_index_age": "1d"
                                }
                            }
                        ]
                    },
                    {
                        "name": "delete",
                        "actions": [
                            {
                                "delete": {}
                            }
                        ],
                        "transitions": []
                    }
                ],
                "ism_template": [
                    {
                        "index_patterns": [
                            "fluent-bit*"
                        ],
                        "priority": 100,
                        "last_updated_time": 1643744811677
                    }
                ]
            }
        }

        '
EOT
  }
  depends_on = [null_resource.fluent_bit_index]
}
