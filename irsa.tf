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

module "aws-fluentbit-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "aws-fluentbit-${local.env_human}"
  create_role           = true
  force_detach_policies = true
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
