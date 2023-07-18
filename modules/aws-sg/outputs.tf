output "security_group_id" {
  value = aws_security_group.vpc_security_group.id
}

output "local_external_ip" {
  value = var.local_external_ip
}