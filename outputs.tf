output "irsa_role_arn" {
  value = module.aws-lb-controller-role.iam_role_arn
}

output "ingress_cert_arn" {
  value = aws_acm_certificate.ingress.arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}
