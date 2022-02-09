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

data "aws_iam_policy_document" "fluentbit" {
  statement {
    actions = [
      "*"
    ]
    effect    = "Allow"
    resources = ["arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/opensearch-${terraform.workspace}"]
  }
}

resource "aws_iam_service_linked_role" "es" {
  count = "${terraform.workspace}" == "dev" ? 1 : 0
  aws_service_name = "es.amazonaws.com"
}
