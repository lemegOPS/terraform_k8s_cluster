output "server_info" {
  value = {
    for server in concat(aws_instance.k8s_mini, aws_instance.k8s_full_cluster) :
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
      "Environment: ${server.tags["Environment"]}"
    ]
  }
}