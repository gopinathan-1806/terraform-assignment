terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Task 2 - remote state + locking.
  # Backend blocks cannot use variables, so values are literals. Create the
  # bucket and table first with ./backend-bootstrap, then run `terraform init`.
  backend "s3" {
    bucket         = "tf-state-devops-assignment-000000000000"
    key            = "task1-ec2-fleet/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-state-locks"
  }
}
