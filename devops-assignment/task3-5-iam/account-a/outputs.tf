output "roleA_arn" {
  value = aws_iam_role.roleA.arn
}

output "roleB_arn" {
  description = "Give this ARN to Account B (it is already hard-coded in account-b/main.tf)."
  value       = aws_iam_role.roleB.arn
}

output "group2_encrypted_passwords" {
  description = "PGP-encrypted initial console passwords (decrypt with your private key)."
  value       = { for k, p in aws_iam_user_login_profile.group2 : k => p.encrypted_password }
}
