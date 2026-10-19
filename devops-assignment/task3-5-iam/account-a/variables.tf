variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "account_a_id" {
  type    = string
  default = "000000000000"
}

variable "account_b_id" {
  type    = string
  default = "111111111111"
}

variable "group1_users" {
  description = "CLI / programmatic-only users."
  type        = set(string)
  default     = ["engine", "ci"]
}

variable "group2_users" {
  description = "Console + CLI users."
  type        = set(string)
  default     = ["alice", "bob"]
}

variable "pgp_key" {
  description = "Base64-encoded PGP public key (or 'keybase:<user>') used to encrypt the initial console passwords so they never sit in state as plaintext."
  type        = string
}

# ---- Task 4 inputs (ci user policy) ----
variable "ecr_repository_name" {
  type    = string
  default = "my-app"
}

variable "ecs_cluster_name" {
  type    = string
  default = "my-cluster"
}

variable "ecs_service_name" {
  type    = string
  default = "my-service"
}

variable "ecs_task_role_names" {
  description = "Task role + execution role used by the task definition (needed for iam:PassRole)."
  type        = list(string)
  default     = ["my-app-task-role", "my-app-task-execution-role"]
}

variable "artifacts_bucket_name" {
  type    = string
  default = "my-build-artifacts-bucket"
}

# Name of the bucket in Account B that roleC may use.
variable "account_b_bucket_name" {
  type    = string
  default = "account-b-shared-data-bucket"
}
