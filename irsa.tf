module "aws-lb-controller-role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "aws-lb-controller-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.aws_lb_controller_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller-${local.env_human}"]
}

resource "aws_iam_policy" "aws_lb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy-${local.env_human}"
  policy = file("lb-controller-iam-policy.json")
}

module "aws-velero-role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "velero-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.velero-backup-policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:velero:velero"]
}

data "template_file" "velero-backup-policy" {
  template = file("${path.module}/velero-backup-policy.json")
  vars = {
    bucket_arn = "${module.s3_bucket_velero_backup.s3_bucket_arn}",
    cluster_arn = "${module.eks.cluster_arn}" 
  }
}

resource "aws_iam_policy" "velero-backup-policy" {
  name   = "velero-backup-${local.env_human}"
  policy = data.template_file.velero-backup-policy.rendered
}

module "aws-fluentbit-role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "aws-fluentbit-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.fluentbit.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:logging:fluent-bit"]
}

resource "aws_iam_policy" "fluentbit" {
  name   = "fluentbit-${local.env_human}"
  policy = data.aws_iam_policy_document.fluentbit.json
}

data "aws_iam_policy_document" "fluentbit" {
  statement {
    actions = [
      "*"
    ]
    effect    = "Allow"
    resources = ["arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.cluster_name}"]
  }
}

module "aws-kubernetes-event-exporter-role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "kubernetes-event-exporter-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.kubernetes-event-exporter.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kubernetes-event-exporter:kubernetes-event-exporter"]
}

resource "aws_iam_policy" "kubernetes-event-exporter" {
  name   = "kubernetes-event-exporter-${local.env_human}"
  policy = data.aws_iam_policy_document.kubernetes-event-exporter.json
}

data "aws_iam_policy_document" "kubernetes-event-exporter" {
  statement {
    actions = [
      "*"
    ]
    effect    = "Allow"
    resources = ["arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.cluster_name}"]
  }
}

module "aws_kubernetes_eso_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "${local.env}-eso"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.eso_ssm_iam_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-secrets:external-secrets"]
}

resource "aws_iam_policy" "eso_ssm_iam_policy" {
  name   = "${local.env}-eso"
  policy = data.aws_iam_policy_document.allow_ssm_read.json
}

data "aws_iam_policy_document" "allow_ssm_read" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter*"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/k8s/${local.env}/*"]
  }
}
