variable "instances" {
  description = <<-EOT
    Map of instances to create. The map key is used as the instance Name tag.
    Exactly one entry must set protected = true; that instance gets
    lifecycle { prevent_destroy = true }.
  EOT

  type = map(object({
    instance_type    = string
    root_volume_type = string
    root_volume_size = number
    root_volume_iops = optional(number) # required for io1 / io2
    key_name         = string           # name of an EXISTING EC2 key pair
    protected        = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for i in values(var.instances) :
      contains(["gp2", "gp3", "io1", "io2"], i.root_volume_type)
    ])
    error_message = "root_volume_type must be one of gp2, gp3, io1, io2 (st1/sc1 cannot be used as a root volume)."
  }

  validation {
    condition = alltrue([
      for i in values(var.instances) :
      contains(["io1", "io2"], i.root_volume_type) ? i.root_volume_iops != null : true
    ])
    error_message = "root_volume_iops must be set for io1 / io2 volumes."
  }

  validation {
    condition = anytrue([
      for i in values(var.instances) : contains(["io1", "io2"], i.root_volume_type)
    ])
    error_message = "At least one instance must use an io1 or io2 root volume."
  }

  validation {
    condition     = length([for i in values(var.instances) : i if i.protected]) == 1
    error_message = "Exactly one instance must have protected = true."
  }
}

variable "environment" {
  description = "Value for the Environment tag."
  type        = string
}

variable "owner" {
  description = "Value for the Owner tag."
  type        = string
}

variable "subnet_id" {
  description = "Subnet in which all instances are launched."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security groups attached to all instances."
  type        = list(string)
}

variable "ami_ssm_parameter" {
  description = "SSM public parameter that resolves to the AMI ID (Amazon Linux 2023 by default)."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
