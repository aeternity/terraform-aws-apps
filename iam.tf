data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_from_account" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "cluster_admin" {
  name               = "${local.env}-cluster-admin"
  assume_role_policy = data.aws_iam_policy_document.assume_from_account.json

  tags = local.standard_tags
}

resource "aws_iam_policy" "autoscaler_policy" {
  name        = "autoscaler-policy-${local.env_human}"
  path        = "/"
  description = "EKS autoscaler policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "autoscaler_policy_attach" {
  role       = module.eks.worker_iam_role_name
  policy_arn = aws_iam_policy.autoscaler_policy.arn
}

resource "aws_iam_policy" "s3_policy" {
  name        = "s3-policy-${local.env_human}"
  path        = "/"
  description = "EKS s3 policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "*"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::aeternity-superhero-graffiti-${local.env_human}"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = module.eks.worker_iam_role_name
  policy_arn = aws_iam_policy.s3_policy.arn
}
