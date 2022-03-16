resource "null_resource" "opensearch_configurations" {  
  provisioner "local-exec" {
    command = "./scripts/opensearch_configurations.sh ${local.opensearch_master_user_password} ${var.opensearch_master_user} ${local.cluster_name} ${module.eks.cluster_iam_role_arn} ${module.eks.worker_iam_role_arn}"
  }
}
