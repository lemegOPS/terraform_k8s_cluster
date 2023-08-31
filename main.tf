locals {
  global_name  = replace("${var.tags["Project"]}-${var.tags["Environment"]}-${var.tags["Name"]}", "-", "_")
  propper_tags = merge(var.tags, { Name = "${local.global_name}" })
  bucket_name  = replace("${var.tags["Project"]}-${var.tags["Environment"]}-${var.tags["Name"]}", "_", "-")
}

module "aws-instance" {
  source                     = "./modules/aws-instance"
  instance_type              = var.instance_type
  tags                       = var.tags
  ami_image                  = var.ami_image
  vpc_security_group         = module.aws-security-group.security_group_id
  global_name                = local.global_name
  private_key_name           = module.aws-private-key.private_key_name
  disk_size                  = var.disk_size
  disk_type                  = var.disk_type
  k8s_type                   = var.k8s_type
  k8s_full_cluster_ammount   = var.k8s_full_cluster_ammount
  k8s_mini_cluster_ammount   = var.k8s_mini_cluster_ammount
  k8s_minikube_nodes_ammount = var.k8s_minikube_nodes_ammount
  iam_role_name              = module.aws-iam.iam_role_name
  bucket_name                = module.aws-s3.bucket_name
  k8s_network                = var.cidr_block
  depends_on                 = [module.aws-iam]
}

module "aws-private-key" {
  source       = "./modules/aws-private-key"
  propper_tags = local.propper_tags
  global_name  = local.global_name
}

module "aws-s3" {
  source      = "./modules/aws-s3"
  tags        = var.tags
  region      = var.region
  profile     = var.profile
  global_name = local.global_name
  bucket_name = local.bucket_name
}

module "aws-security-group" {
  source                = "./modules/aws-security-group"
  vpc_id                = module.aws-vpc.vpc_id
  sg_port               = var.sg_port
  cidr_block            = var.cidr_block
  propper_tags          = local.propper_tags
  global_name           = local.global_name
  tags                  = var.tags
  local_external_ip     = var.local_external_ip
  default_subnets       = module.aws-vpc.default_vpc_subnets
  k8s_full_external_ips = module.aws-instance.k8s_full_external_ips
}

module "aws-vpc" {
  source = "./modules/aws-vpc"
}

module "aws-iam" {
  source      = "./modules/aws-iam"
  global_name = local.global_name
  bucket_name = module.aws-s3.bucket_name
  tags        = var.tags
}