data "aws_region" "current" {}

data "aws_iam_role" "service_linked_role" {
  name = "AWSServiceRoleForAmazonElasticsearchService"
}

module "opensearch" {
  source          = "./modules/terraform-aws-opensearch"
  cluster_name    = local.cluster_name
  cluster_domain  = local.cluster_domain
  cluster_version = "1.1"

  warm_instance_enabled   = var.warm_instance_enabled[local.env_human]
  master_instance_count   = var.master_instance_count[local.env_human]
  master_instance_enabled = var.master_instance_enabled[local.env_human]
  hot_instance_count      = var.hot_instance_count[local.env_human]
  availability_zones      = var.availability_zones[local.env_human]
  master_user_name        = "es-admin"
  master_user_password    = var.opensearch_master_user_password[local.env_human]
  ebs_enabled             = var.ebs_enabled[local.env_human]
  volume_size             = var.volume_size[local.env_human]
  hot_instance_type       = var.hot_instance_type[local.env_human]
  aws_iam_service_linked_role_es = local.es_linked_role
}

resource "null_resource" "opensearch_config" {  
  provisioner "local-exec" {
    command = "./scripts/opensearch_config.sh ${local.opensearch_master_user_password} ${var.opensearch_master_user} ${local.cluster_name} ${module.eks.cluster_iam_role_arn} ${module.eks.worker_iam_role_arn}"
  }
}
