#----------- AWS AMI & AMI data block ----------#

data "aws_ami" "image" {
  owners      = var.ami_image["ami_owners"]
  most_recent = true
  filter {
    name   = var.ami_image["ami_filter_name"]
    values = var.ami_image["ami_filter_value"]
  }
}

resource "aws_instance" "k8s_mini" {
  count                       = var.k8s_type != "k8s_full" ? var.k8s_mini_cluster_ammount : 0
  ami                         = data.aws_ami.image.id
  instance_type               = lookup(var.instance_type, var.k8s_type)
  key_name                    = var.private_key_name
  vpc_security_group_ids      = [var.vpc_security_group]
  associate_public_ip_address = true

  user_data = templatefile("userdata.tpl", {
    k8s_minikube_nodes_ammount = var.k8s_minikube_nodes_ammount
    k8s_type                   = var.k8s_type
    K8S_role                   = "none"
    bucket_name                = "none"
    k8s_network                = "none"
  })

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size           = var.disk_size
    volume_type           = var.disk_type
    delete_on_termination = true
    tags = merge(var.tags,
      {
        Name = "${var.global_name}_${count.index + 1}"
    })
  }

  tags = merge(var.tags,
    {
      Name = "${var.global_name}_${count.index + 1}"
  })
}

resource "aws_instance" "k8s_full_cluster" {
  count                       = var.k8s_type == "k8s_full" ? var.k8s_full_cluster_ammount : 0
  ami                         = data.aws_ami.image.id
  instance_type               = lookup(var.instance_type, var.k8s_type)
  key_name                    = var.private_key_name
  vpc_security_group_ids      = [var.vpc_security_group]
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_role_name

  provisioner "remote-exec" {
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.global_name}_id_rsa.pem")
    }
    inline = [
      "sudo hostnamectl set-hostname ${count.index == 0 ? "Master" : "Worker-${count.index}"}"
    ]
  }

  user_data = templatefile("userdata.tpl", {
    k8s_minikube_nodes_ammount = "none"
    k8s_type                   = var.k8s_type
    K8S_role                   = count.index == 0 ? "Master" : "Worker"
    bucket_name                = var.bucket_name
    k8s_network                = var.k8s_network["k8s_network"]
  })

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size           = var.disk_size
    volume_type           = var.disk_type
    delete_on_termination = true

    tags = count.index == 0 ? merge(var.tags, {
      Name = "Master_${var.global_name}_${count.index + 1}" }, { K8S_role = "Master" }) : merge(var.tags, {
    Name = "Worker_${var.global_name}_${count.index}" }, { K8S_role = "Worker" })
  }

  tags = count.index == 0 ? merge(var.tags, {
    Name = "Master_${var.global_name}_${count.index + 1}" }, { K8S_role = "Master" }) : merge(var.tags, {
  Name = "Worker_${var.global_name}_${count.index}" }, { K8S_role = "Worker" })
}