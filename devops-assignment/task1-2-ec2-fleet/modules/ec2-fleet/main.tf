data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
  }

  # prevent_destroy must be a literal in HCL (it cannot be driven by a
  # variable or each.value), so the single input map is split in two and each
  # half feeds one resource block. Everything else is identical.
  protected_instances = { for k, v in var.instances : k => v if v.protected }
  standard_instances  = { for k, v in var.instances : k => v if !v.protected }
}

resource "aws_instance" "protected" {
  for_each = local.protected_instances

  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = each.value.instance_type
  key_name               = each.value.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = each.value.root_volume_iops
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }

  tags        = merge(local.common_tags, { Name = each.key })
  volume_tags = merge(local.common_tags, { Name = each.key })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "standard" {
  for_each = local.standard_instances

  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = each.value.instance_type
  key_name               = each.value.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = each.value.root_volume_iops
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }

  tags        = merge(local.common_tags, { Name = each.key })
  volume_tags = merge(local.common_tags, { Name = each.key })
}
