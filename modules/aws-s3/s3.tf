#----------- Bucket create block ----------#

resource "random_string" "bucket_prefix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "bucket_state" {
  bucket = lower("${var.bucket_name}-tfstate-${random_string.bucket_prefix.id}")
  lifecycle {
    prevent_destroy = false
  }
  tags = merge(var.tags, { Name = "${var.global_name}" })
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encrypt" {
  bucket = aws_s3_bucket.bucket_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


#----------- TFstate upload block ----------#

resource "aws_s3_object" "bucket_tfstate_upload" {
  bucket = aws_s3_bucket.bucket_state.id
  source = "terraform.tfstate"
  key    = lower("${var.bucket_name}/terraform.tfstate")
  tags   = merge(var.tags, { Name = "${var.global_name}" })
}

data "terraform_remote_state" "bucket_tfstate_data" {
  backend = "s3"
  config = {
    bucket  = aws_s3_bucket.bucket_state.id
    key     = aws_s3_object.bucket_tfstate_upload.id
    region  = var.region
    profile = var.profile
  }
}