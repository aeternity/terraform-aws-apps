variable "apps_domain" {
  default = "aepps.com"
}

variable "tools_domain" {
  default = "aeternity.io"
}

variable "opensearch_master_user" {
  default = "es-admin"
}

variable "opensearch_master_user_password" {
  type = map(any)
}

variable "aws_region" {
  default = "eu-central-1"
}
