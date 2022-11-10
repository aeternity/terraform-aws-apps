module "s3_bucket_velero_backup" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.0.1"
  bucket  = "aeternity-velero-backup-${local.env_human}"
  acl     = "private"

  versioning = {
    enabled = true
  }
}
