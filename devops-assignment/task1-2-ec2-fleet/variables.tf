variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "subnet_id" {
  description = "Existing subnet ID"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Existing security group IDs."
  type        = list(string)
}

# Single input that drives all 5 instances. Key pairs must already exist.
variable "instances" {
  type = map(object({
    instance_type    = string
    root_volume_type = string
    root_volume_size = number
    root_volume_iops = optional(number)
    key_name         = string
    protected        = optional(bool, false)
  }))

  default = {
    "web-1" = {
      instance_type    = "t3.micro"
      root_volume_type = "gp3"
      root_volume_size = 20
      key_name         = "kp-web-1"
    }
    "web-2" = {
      instance_type    = "t3.small"
      root_volume_type = "gp3"
      root_volume_size = 30
      key_name         = "kp-web-2"
    }
    "app-1" = {
      instance_type    = "m5.large"
      root_volume_type = "gp2"
      root_volume_size = 50
      key_name         = "kp-app-1"
    }
    "batch-1" = {
      instance_type    = "c5.large"
      root_volume_type = "gp3"
      root_volume_size = 40
      key_name         = "kp-batch-1"
    }
    "db-1" = {
      instance_type    = "r5.large"
      root_volume_type = "io2"
      root_volume_size = 100
      root_volume_iops = 3000
      key_name         = "kp-db-1"
      protected        = true
    }
  }
}
