module "aws-lb-controller-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "aws-lb-controller-${local.env_human}"
  create_role           = true
  force_detach_policies = true
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
    bucket_arn = "${module.s3_bucket_velero_backup.s3_bucket_arn}"
  }
}

resource "aws_iam_policy" "velero-backup-policy" {
  name   = "velero-backup-${local.env_human}"
  policy = data.template_file.velero-backup-policy.rendered
}
