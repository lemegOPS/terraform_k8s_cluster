output "bucket_name" {
  value = aws_s3_bucket.state_bucket.id
}

output "key" {
  value = aws_s3_object.bucket_tfstate_upload.id
}