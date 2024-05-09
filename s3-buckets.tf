resource "aws_s3_bucket" "graffiti_server" {
  bucket = "aeternity-graffiti-server-${local.env_human}"

  tags = local.standard_tags
}
