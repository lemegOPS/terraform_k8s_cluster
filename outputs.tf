#----------Bucket output----------#
output "bucket_name" {
  value       = module.aws-s3.bucket_name
  description = "Show created bucket name for this module"
}

#----------Server output----------#
output "server_info" {
  value       = module.aws-instance.server_info
  description = "Show server info: ID, Instance type, AMI, SSH key name, External IP ore DNS, Internal IP Project, Owner, Project, Env"
}

#----------VPC output----------#
output "vpc_id" {
  value = module.aws-vpc.vpc_id
}
