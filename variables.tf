variable "apps_domain" {
  default = "aepps.com"
}

variable "tools_domain" {
  default = "aeternity.io"
}

variable "warm_instance_enabled" {
  default = {
    "dev" = "false"
    "stg" = "false"
    "prd" = "false"
  }
}

variable "master_instance_count" {
  default = {
    "dev" = "1"
    "stg" = "1"
    "prd" = "1"
  }
}

variable "master_instance_enabled" {
  default = {
    "dev" = "false"
    "stg" = "false"
    "prd" = "false"
  }
}

variable "hot_instance_count" {
  default = {
    "dev" = "1"
    "stg" = "1"
    "prd" = "2"
  }
}

variable "availability_zones" {
  default = {
    "dev" = "1"
    "stg" = "1"
    "prd" = "2"
  }
}

variable "opensearch_master_user_password" {
  type = map(any)
}

variable "ebs_enabled" {
  default = {
    "dev" = true
    "stg" = true
    "prd" = true
  }
}

variable "volume_size" {
  default = {
    "dev" = "100"
    "stg" = "100"
    "prd" = "500"
  }
}

variable "aws_region" {
  default = "eu-central-1"
}

variable "hot_instance_type" {
  default = {
    "dev" = "t3.medium.elasticsearch"
    "stg" = "t3.medium.elasticsearch"
    "prd" = "t3.medium.elasticsearch"
  }
}
