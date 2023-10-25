module "aws-lb-controller-role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "aws-lb-controller-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.aws_lb_controller_policy.arn]
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
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "velero-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.velero-backup-policy.arn]
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

module "aws-fluentbit-role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "aws-fluentbit-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.fluentbit.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:monitoring:fluent-bit",
    "system:serviceaccount:logging:fluent-bit",
    "system:serviceaccount:tools:fluent-bit",
  ]
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
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:tools:kubernetes-event-exporter",
    "system:serviceaccount:kubernetes-event-exporter:kubernetes-event-exporter"
  ]
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
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "cert-manager-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cert-manager-policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:tools:cert-manager",
    "system:serviceaccount:cert-manager:cert-manager"
  ]
}

resource "aws_iam_policy" "cert-manager-policy" {
  name   = "cert-manager-${local.env_human}"
  policy = file("cert-manager-policy.json")
}


# resource "aws_iam_role" "ebs_csi_driver_role" {
#   name = "ebs_csi_driver_role-${local.env_human}"
#   assume_role_policy = templatefile("${path.module}/aws-ebs-csi-driver-trust-policy.json", {
#     account_id   = data.aws_caller_identity.current.account_id,
#     provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
#   })
# }

# resource "aws_iam_role_policy_attachment" "ebs_role_attachment" {
#   role = aws_iam_role.ebs_csi_driver_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

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
