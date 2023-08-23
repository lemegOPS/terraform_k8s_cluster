#----------- Global variables -----------#

variable "profile" {
  default     = "aws_own"
  description = "This is profile name wich is configured in ~/.aws/config"
}

variable "region" {
  default     = "us-east-1"
  description = "Region"
}

variable "tags" {
  type = map(any)
  default = {
    Project     = "Learning"
    Name        = "K8S"
    Environment = "test"
  }
  description = "Use this map of tags. Use to generate bucket name, names or resources, tags. See global_name in module"
}


#----------- Instance variables -----------#

variable "instance_type" {
  type = map(any)
  default = {
    k8s_full = "t3.small"  #2 vCPU/2 GiB RAM | 0.0208 USD per Hour
    dind     = "t2.medium" #2 vCPU/4 GiB RAM | 0.0464 USD per Hour 
    minikube = "t2.medium" #2 vCPU/4 GiB RAM | 0.0464 USD per Hour
  }
  description = "Requires at least 2 cpu and 2 memory"
}

variable "ami_image" {
  type = object({
    ami_owners       = list(string)
    ami_filter_value = list(string)
    ami_filter_name  = string
  })
  default = {
    ami_owners       = ["amazon"]
    ami_filter_value = ["amzn2-ami-hvm-*-x86_64-gp2"]
    ami_filter_name  = "name"
  }
  description = "Add owner and ami_name to search and choose most recent ami"
}

variable "disk_size" {
  default     = "20"
  description = "Must be at least 20 gb sick space for normal work of k8s cluster"
}

variable "disk_type" {
  default     = "gp3"
  description = "GP3 gives optimized speed"
}

variable "k8s_full_cluster_ammount" {
  default     = "3"
  description = "Ammount of FULL K8S cluster"
}

variable "k8s_mini_cluster_ammount" {
  default     = "1"
  description = "Ammount of EC2 instance on MINI K8S cluster such as dind ore minikube (NOT K8S FULL cluster)"
}

variable "k8s_minikube_nodes_ammount" {
  default     = "3"
  description = "Ammount of nodes in minikude EC2 instance"
}

variable "k8s_type" {
  default     = "k8s_full"
  description = "Must be k8s_full ore dind ore minikube"
}


#----------- VPC variables -----------#

variable "cidr_block" {
  type = map(any)
  default = {
    external = "0.0.0.0/0"
    internal = "10.0.0.0/16"
  }
  description = "Cidr Block map. Use for network"
}

variable "sg_port" {
  default     = ["22", "80", "443", "8080", "6443"]
  description = "Ports for Security group"
}

variable "local_external_ip" {
  default = ""
}