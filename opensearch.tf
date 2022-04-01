data "aws_region" "current" {}

data "aws_iam_role" "service_linked_role" {
  name = "AWSServiceRoleForAmazonElasticsearchService"
}

module "opensearch" {
  source          = "./modules/terraform-aws-opensearch"
  cluster_name    = local.cluster_name
  cluster_domain  = local.cluster_domain
  cluster_version = "1.1"

  warm_instance_enabled          = local.config.warm_instance_enabled
  master_instance_count          = local.config.master_instance_count
  master_instance_enabled        = local.config.master_instance_enabled
  hot_instance_count             = local.config.hot_instance_count
  availability_zones             = local.config.availability_zones
  master_user_name               = var.opensearch_master_user
  master_user_password           = local.opensearch_master_user_password
  ebs_enabled                    = local.config.ebs_enabled
  volume_size                    = local.config.volume_size
  hot_instance_type              = local.config.hot_instance_type
  aws_iam_service_linked_role_es = local.es_linked_role
}
