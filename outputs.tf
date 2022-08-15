output "irsa_role_arn" {
  value = module.aws-lb-controller-role.iam_role_arn
}

output "ingress_cert_arn" {
  value = aws_acm_certificate.ingress.arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "cluster_iam_role_arn" {
  value = module.eks.cluster_iam_role_arn
}

output "worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}

output "worker_iam_role_name" {
  value = module.eks.worker_iam_role_name
}

output "opensearch_master_user_password" {
  value     = random_string.opensearch_master_user_password.result
  sensitive = true
}

output "velero_backeup_s3_bucket_arn" {
  value = module.s3_bucket_velero_backup.s3_bucket_arn
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "cluser_admin_iam_role_arn" {
  value = aws_iam_role.cluster_admin.arn
}

output "eso_role_arn" {
  value = module.aws_kubernetes_eso_role.iam_role_arn
}
