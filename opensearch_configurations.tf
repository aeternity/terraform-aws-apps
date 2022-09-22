resource "null_resource" "opensearch_configurations_fluentbit" {  
  provisioner "local-exec" {
    command = "./modules/terraform-aws-opensearch/scripts/opensearch_configurations.sh '${local.opensearch_master_user_password}' ${var.opensearch_master_user} ${local.cluster_name} ${module.eks.cluster_iam_role_arn} ${module.eks.worker_iam_role_arn} fluent-bit fluentbit"
  }
}

resource "null_resource" "opensearch_configurations_kube_events" {  
  provisioner "local-exec" {
    command = "./modules/terraform-aws-opensearch/scripts/opensearch_configurations.sh '${local.opensearch_master_user_password}' ${var.opensearch_master_user} ${local.cluster_name} ${module.eks.cluster_iam_role_arn} ${module.eks.worker_iam_role_arn} k8s-events k8sevents"
  }
}

resource "null_resource" "opensearch_configurations_fluentbitHetzner" {  
  provisioner "local-exec" {
    command = "./modules/terraform-aws-opensearch/scripts/opensearch_configurations.sh '${local.opensearch_master_user_password}' ${var.opensearch_master_user} ${local.cluster_name} ${module.eks.cluster_iam_role_arn} ${module.eks.worker_iam_role_arn} fluent-hetzner fluentbitHetzner"
  }
}
