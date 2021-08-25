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
