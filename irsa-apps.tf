module "aws_graffiti_server_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version               = "4.2.0"
  role_name             = "graffiti-server-${local.env_human}"
  create_role           = true
  force_detach_policies = true
  provider_url          = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns      = [aws_iam_policy.graffiti_server_iam_policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:apps:graffiti-server-testnet-app",
    "system:serviceaccount:apps:graffiti-server-mainnnet-app",
  ]
}

resource "aws_iam_policy" "graffiti_server_iam_policy" {
  name   = "graffiti-server-${local.env_human}"
  policy = data.aws_iam_policy_document.graffiti_allow_s3.json
}

data "aws_iam_policy_document" "graffiti_allow_s3" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.graffiti_server.arn,
      "${aws_s3_bucket.graffiti_server.arn}/*"
    ]
  }
}
