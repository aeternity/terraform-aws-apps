module "s3_bucket_velero_backup" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "velero-backup-${local.env_human}"
  acl    = "private"

  versioning = {
    enabled = false
  }
}
