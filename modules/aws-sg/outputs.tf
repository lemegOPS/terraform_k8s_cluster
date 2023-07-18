output "security_group_id" {
  value = aws_security_group.vpc_security_group.id
}

output "local_external_ip" {
  value = chomp(data.http.local_external_ip.response_body)
}