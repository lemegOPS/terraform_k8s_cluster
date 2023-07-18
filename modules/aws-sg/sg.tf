#---------- Security Group block ----------#

data "http" "local_external_ip" {
  url = "http://ifconfig.co/ip"
}

resource "aws_security_group" "vpc_security_group" {
  name   = "${var.global_name}_SG"
  vpc_id = var.vpc_id
  dynamic "ingress" {
    for_each = var.sg_port
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["${chomp(data.http.local_external_ip.response_body)}/32"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block["external"]]
  }
  tags = var.propper_tags
}