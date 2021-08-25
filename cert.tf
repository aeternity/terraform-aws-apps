data "aws_route53_zone" "apps" {
  name         = "${var.apps_domain}."
}

data "aws_route53_zone" "tools" {
  name         = "${var.tools_domain}."
}

resource "aws_acm_certificate" "ingress" {
  # provider                  = aws.us-east-1
  validation_method         = "DNS"
  domain_name               = "${local.env_human}.${var.apps_domain}"
  subject_alternative_names = [
    "${local.env_human}.${var.tools_domain}",
    "*.${local.env_human}.${var.tools_domain}",
    "*.${local.env_human}.${var.apps_domain}"
  ]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ingress.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = can(regex(var.apps_domain, dvo.domain_name)) ? data.aws_route53_zone.apps.zone_id : data.aws_route53_zone.tools.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "ingress" {
  certificate_arn         = aws_acm_certificate.ingress.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
