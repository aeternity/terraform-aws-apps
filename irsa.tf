module "aws-lb-controller-role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "aws-lb-controller-${terraform.workspace}"
  create_role           = true
  force_detach_policies = true
  # provider_url          = module.eks.cluster_oidc_issuer_url
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.aws_lb_controller_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
}

resource "aws_iam_policy" "aws_lb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy-${terraform.workspace}"
  policy = file("lb-controller-iam-policy.json")
}
