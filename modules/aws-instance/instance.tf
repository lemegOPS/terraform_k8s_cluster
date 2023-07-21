#----------- AWS AMI & AMI data block ----------#

data "aws_ami" "image" {
  owners      = var.ami_image["ami_owners"]
  most_recent = true
  filter {
    name   = var.ami_image["ami_filter_name"]
    values = var.ami_image["ami_filter_value"]
  }
}

data "template_file" "userdata_file" {
  template = file("userdata.tpl")
  vars = {
    node_ammount = var.k8s_full_ammount
    k8s_type     = var.k8s_type
  }
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.image.id
  instance_type               = lookup(var.instance_type, var.k8s_type)
  user_data                   = data.template_file.userdata_file.rendered
  count                       = var.k8s_type == "k8s_full" ? var.k8s_full_ammount : 1
  key_name                    = var.private_key_name
  vpc_security_group_ids      = [var.vpc_security_group]
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_size           = var.disk_size
    volume_type           = var.disk_type
    delete_on_termination = true
  }

  tags = merge(var.tags, { Name = "${var.global_name}_${count.index + 1}" })
}