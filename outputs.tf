#---------- Bucket output ----------#
output "bucket_name" {
  value       = module.aws-s3.bucket_name
  description = "Show created bucket name for this module"
}


#---------- VPC output ----------#
output "vpc_id" {
  value = module.aws-vpc.vpc_id
}

output "local_external_ip" {
  value = module.aws-security-group.local_external_ip
}


#---------- Server output ----------#
output "server_info" {
  value       = module.aws-instance.server_info
  description = "Show server info: ID, Instance type, AMI, SSH key name, External IP ore DNS, Internal IP Project, Owner, Project, Env"
}


#---------- AIM output ----------#
output "iam_role_name" {
  value = module.aws-iam.iam_role_name
}