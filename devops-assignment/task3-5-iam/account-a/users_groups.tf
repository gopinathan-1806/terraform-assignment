# ---------------------------------------------------------------------------
# Users and groups (Account A)
# ---------------------------------------------------------------------------

resource "aws_iam_user" "group1" {
  for_each = var.group1_users
  name     = each.key
  path     = "/service/"
}

resource "aws_iam_user" "group2" {
  for_each = var.group2_users
  name     = each.key
  path     = "/people/"
}

# group1: programmatic only. No aws_iam_user_login_profile is created for these
# users, so they have no console password and cannot sign in to the console.
resource "aws_iam_group" "group1" {
  name = "group1"
}

resource "aws_iam_group_membership" "group1" {
  name  = "group1-membership"
  group = aws_iam_group.group1.name
  users = [for u in aws_iam_user.group1 : u.name]
}

# group1's only group-level permission: hop into roleB (which in turn can only
# hop into roleC in Account B). Everything else comes from per-user policies.
data "aws_iam_policy_document" "group1" {
  statement {
    sid       = "AssumeRoleB"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.roleB.arn]
  }
}

resource "aws_iam_group_policy" "group1" {
  name   = "assume-roleB"
  group  = aws_iam_group.group1.name
  policy = data.aws_iam_policy_document.group1.json
}

# group2: console + CLI.
resource "aws_iam_group" "group2" {
  name = "group2"
}

resource "aws_iam_group_membership" "group2" {
  name  = "group2-membership"
  group = aws_iam_group.group2.name
  users = [for u in aws_iam_user.group2 : u.name]
}

# "Full" access for group2. Replace with a narrower policy if needed.
resource "aws_iam_group_policy_attachment" "group2_admin" {
  group      = aws_iam_group.group2.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Console access: login profile with a forced password change. The generated
# password is PGP-encrypted in the output/state.
resource "aws_iam_user_login_profile" "group2" {
  for_each                = aws_iam_user.group2
  user                    = each.value.name
  pgp_key                 = var.pgp_key
  password_reset_required = true
}
