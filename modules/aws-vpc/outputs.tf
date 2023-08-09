output "vpc_id" {
  value = aws_default_vpc.default_vpc.id
}

output "default_vpc_subnets" {
  value = data.aws_vpc.default_vpc_subnets.cidr_block
}