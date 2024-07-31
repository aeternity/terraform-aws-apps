module "aws-lb-controller-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "aws-lb-controller-${local.env_human}"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.aws_lb_controller_policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:tools:aws-load-balancer-controller",
    "system:serviceaccount:kube-system:aws-load-balancer-controller-${local.env_human}"
  ]
}

resource "aws_iam_policy" "aws_lb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy-${local.env_human}"
  policy = file("lb-controller-iam-policy.json")
}



module "aws-velero-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "velero-${local.env_human}"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.velero-backup-policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:tools:velero",
    "system:serviceaccount:velero:velero"
  ]
}

resource "aws_iam_policy" "velero-backup-policy" {
  name = "velero-backup-${local.env_human}"
  policy = templatefile("${path.module}/velero-backup-policy.json", {
    bucket_arn  = "${module.s3_bucket_velero_backup.s3_bucket_arn}",
    cluster_arn = "${module.eks.cluster_arn}"
  })
}

module "aws_kubernetes_eso_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "${local.env}-eso"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.eso_ssm_iam_policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:tools:external-secrets",
    "system:serviceaccount:external-secrets:external-secrets"
  ]
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



module "aws-cert-manager-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "cert-manager-${local.env_human}"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.cert-manager-policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:tools:cert-manager",
    "system:serviceaccount:cert-manager:cert-manager"
  ]
}

resource "aws_iam_policy" "cert-manager-policy" {
  name   = "cert-manager-${local.env_human}"
  policy = file("cert-manager-policy.json")
}



module "aws-prometheus-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "prometheus-${local.env_human}"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.prometheus-policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:monitoring:kube-prometheus-stack-prometheus",
  ]
}

resource "aws_iam_policy" "prometheus-policy" {
  name   = "prometheus-${local.env_human}"
  policy = file("prometheus-policy.json")
}



module "aws-ebs-controller-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "aws-ebs-controller-${local.env_human}"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.aws-ebs-controller-policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:aws-ebs-controller-${local.env_human}",
    "system:serviceaccount:kube-system:ebs-csi-controller-sa"
  ]
}

resource "aws_iam_policy" "aws-ebs-controller-policy" {
  name   = "aws-ebs-controller-${local.env_human}"
  policy = file("aws-ebs-controller-policy.json")
}

module "aws_loki_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "loki-${local.env_human}"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.loki_iam_policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:monitoring:loki",
  ]
}

resource "aws_iam_policy" "loki_iam_policy" {
  name   = "loki-${local.env_human}"
  policy = data.aws_iam_policy_document.loki_allow_s3.json
}

// https://grafana.com/docs/loki/latest/operations/storage/#s3
data "aws_iam_policy_document" "loki_allow_s3" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.loki_chunks.arn,
      aws_s3_bucket.loki_ruler.arn,
      # aws_s3_bucket.loki_admin.arn,
      "${aws_s3_bucket.loki_chunks.arn}/*",
      "${aws_s3_bucket.loki_ruler.arn}/*",
      # "${aws_s3_bucket.loki_admin.arn}/*",
    ]
  }
}

