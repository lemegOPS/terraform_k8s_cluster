output "bucket_name" {
  value = aws_s3_bucket.bucket_state.id
}

output "key" {
  value = aws_s3_object.bucket_tfstate_upload.id
}