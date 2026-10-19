# Task 4 - least-privilege custom policy for the `ci` user.
# The JSON lives in policies/ci-policy.json.tpl; Terraform only fills in names.

resource "aws_iam_user_policy" "ci" {
  name = "ci-pipeline-least-privilege"
  user = aws_iam_user.group1["ci"].name

  policy = templatefile("${path.module}/policies/ci-policy.json.tpl", {
    region           = var.aws_region
    account_id       = var.account_a_id
    ecr_repository   = var.ecr_repository_name
    ecs_cluster      = var.ecs_cluster_name
    ecs_service      = var.ecs_service_name
    artifacts_bucket = var.artifacts_bucket_name
    task_role_arns = jsonencode([
      for r in var.ecs_task_role_names : "arn:aws:iam::${var.account_a_id}:role/${r}"
    ])
  })
}
