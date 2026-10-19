# ---------------------------------------------------------------------------
# roleA: administrative access to all services EXCEPT IAM
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "roleA_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [for u in aws_iam_user.group2 : u.arn]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "roleA" {
  name               = "roleA"
  assume_role_policy = data.aws_iam_policy_document.roleA_trust.json
}

data "aws_iam_policy_document" "roleA_permissions" {
  statement {
    sid       = "AllowEverything"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  # An explicit Deny always wins, so IAM is blocked even though "*" is allowed.
  statement {
    sid       = "DenyIAM"
    effect    = "Deny"
    actions   = ["iam:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "roleA" {
  name   = "admin-except-iam"
  role   = aws_iam_role.roleA.id
  policy = data.aws_iam_policy_document.roleA_permissions.json
}

# ---------------------------------------------------------------------------
# roleB: only permission is to assume roleC in Account B
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "roleB_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [for u in aws_iam_user.group1 : u.arn]
    }
  }
}

resource "aws_iam_role" "roleB" {
  name               = "roleB"
  assume_role_policy = data.aws_iam_policy_document.roleB_trust.json
}

data "aws_iam_policy_document" "roleB_permissions" {
  statement {
    sid       = "AssumeRoleCInAccountB"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${var.account_b_id}:role/roleC"]
  }
}

resource "aws_iam_role_policy" "roleB" {
  name   = "assume-roleC-only"
  role   = aws_iam_role.roleB.id
  policy = data.aws_iam_policy_document.roleB_permissions.json
}
