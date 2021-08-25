output "irsa_role_arn" {
  value = module.aws-lb-controller-role.iam_role_arn
}

output "ingress_cert_arn" {
  value = aws_acm_certificate.ingress.arn
}
