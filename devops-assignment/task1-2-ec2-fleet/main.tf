provider "aws" {
  region = var.aws_region
}

module "ec2_fleet" {
  source = "./modules/ec2-fleet"

  instances              = var.instances
  environment            = var.environment
  owner                  = var.owner
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
}
