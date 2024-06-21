resource "aws_s3_bucket" "loki_chunks" {
  bucket = "aeternity-loki-chunks-${local.env_human}"

  tags = local.standard_tags
}

resource "aws_s3_bucket" "loki_ruler" {
  bucket = "aeternity-loki-ruler-${local.env_human}"

  tags = local.standard_tags
}

# resource "aws_s3_bucket" "loki_admin" {
#   bucket = "aeternity-loki-admin-${local.env_human}"

#   tags = local.standard_tags
# }

resource "aws_s3_bucket" "graffiti_server" {
  bucket = "aeternity-graffiti-server-${local.env_human}"

  tags = local.standard_tags
}
