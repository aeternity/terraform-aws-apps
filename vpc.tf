module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name                 = "${local.env}-vpc"
  cidr                 = local.config.cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = local.config.private_subnets
  public_subnets       = local.config.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.env}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.env}" = "shared"
    "kubernetes.io/role/elb"             = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.env}" = "shared"
    "kubernetes.io/role/internal-elb"    = "1"
  }
}
