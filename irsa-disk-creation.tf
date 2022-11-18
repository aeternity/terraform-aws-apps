module "aws-ebs-controller-role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.2.0"
  role_name                     = "aws-ebs-controller-${local.env_human}"
  create_role                   = true
  force_detach_policies         = true
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.aws_ebs_controller_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-ebs-csi-driver-${local.env_human}"]
}

resource "aws_iam_policy" "aws_ebs_controller_policy" {
  name   = "AWSElasticBlockStoreControllerIAMPolicy-${local.env_human}"
  policy = file("aws-ebs-csi-driver-trust-policy.json")
}
