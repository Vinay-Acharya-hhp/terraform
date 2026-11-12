locals {
  github_subjects = {
    # PRs may only plan
    plan = ["repo:${var.github_repo}:pull_request"]
    # Only main (or the "dev" GitHub environment, if the workflow uses one) may apply
    apply = [
      "repo:${var.github_repo}:ref:refs/heads/main",
      "repo:${var.github_repo}:environment:dev",
    ]
  }
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_trust" {
  for_each = local.github_subjects

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "ci" {
  for_each = data.aws_iam_policy_document.github_trust

  name               = "${var.name_prefix}-github-${each.key}"
  assume_role_policy = each.value.json
}

# Plan role: read-only on AWS, plus access to the state bucket
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.ci["plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*"]
  }
  # use_lockfile writes a .tflock object even during plan
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "state-bucket-access"
  role   = aws_iam_role.ci["plan"].id
  policy = data.aws_iam_policy_document.plan_state.json
}

# Apply role: admin for now; scope down once the stacks are stable
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.ci["apply"].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}