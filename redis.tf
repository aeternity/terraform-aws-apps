locals {
  name       = "Redis"
  redis_tags = merge({ "Name" : local.name }, local.standard_tags)
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.4.0"

  name        = local.name
  description = "Security group for Redis"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["10.0.0.0/16"]
  ingress_rules       = ["redis-tcp"]
  egress_rules        = ["all-all"]

  tags = local.redis_tags
}

module "redis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.2.0"

  name                  = local.name
  key_name              = "temp"
  instance_type         = "t2.medium"
  ami                   = "ami-049dba36e59403eff"
  subnet_id             = module.vpc.private_subnets[0]
  secondary_private_ips = ["10.0.1.11"]
  tags                  = local.redis_tags
}

resource "aws_volume_attachment" "this" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this.id
  instance_id = module.redis.id
}

resource "aws_ebs_volume" "this" {
  availability_zone = data.aws_availability_zones.available.names[0]
  # size should be configured per requirements for each environment, we have to choose and disk type
  size = 10
  type = "gp3"
  tags = local.redis_tags
}
