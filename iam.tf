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
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
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

resource "aws_iam_service_linked_role" "es" {
  count            = "${local.env_human}" == "dev" ? 1 : 0
  aws_service_name = "es.amazonaws.com"
}
