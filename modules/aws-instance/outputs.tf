output "server_info" {
  value = {
    for server in aws_instance.server :
    server.tags["Name"] => [
      "######### Instance info #########",
      "ID: ${server.id}",
      "Instance type: ${server.instance_type}",
      "AMI: ${server.ami}",
      "SSH Key: ${server.key_name}",
      "---------------------------------------",
      "######### Network info #########",
      "External IP: ${server.public_ip}",
      "External DNS: ${server.public_dns}",
      "Internal IP: ${server.private_ip}",
      "---------------------------------------",
      "######### Manegment info #########",
      "Project: ${server.tags["Project"]}",
      "Owner: ${server.tags["Owner"]}",
      "Environment: ${server.tags["Environment"]}"
    ]
  }
}

output "servers" {
  value = aws_instance.server[*].id
}