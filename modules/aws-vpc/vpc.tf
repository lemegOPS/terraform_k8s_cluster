resource "aws_default_vpc" "default_vpc" {}

data "aws_vpc" "default_vpc_subnets" {
  default = true
}