#---------- Security Group block ----------#

data "http" "local_external_ip" {
  url = "http://ifconfig.co/ip"
}

resource "aws_security_group" "vpc_security_group" {
  name   = "${var.global_name}_SG"
  vpc_id = var.vpc_id
  tags   = var.propper_tags
}

resource "aws_security_group_rule" "k8s_full_allow_from_local_ip" {
  description       = "Allow all ports from your local IP (you PC IP)"
  security_group_id = aws_security_group.vpc_security_group.id
  count             = length(var.sg_port)
  type              = "ingress"
  from_port         = tonumber(var.sg_port[count.index])
  to_port           = tonumber(var.sg_port[count.index])
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.local_external_ip.response_body)}/32"]
}

resource "aws_security_group_rule" "k8s_full_allow_master_to_worker_internal" {
  description       = "Allow all ports from all instances to each other"
  security_group_id = aws_security_group.vpc_security_group.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.default_subnets]
}

resource "aws_security_group_rule" "k8s_full_master_worker_snat" {
  description       = "Allow external connection from master (for kuberbetes svc external-ip)"
  security_group_id = aws_security_group.vpc_security_group.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = formatlist("%s/32", concat(var.k8s_full_external_ips))
}

resource "aws_security_group_rule" "k8s_full_egress_rule" {
  description       = "Allow all incoming traffic"
  security_group_id = aws_security_group.vpc_security_group.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.cidr_block["external"]]
}