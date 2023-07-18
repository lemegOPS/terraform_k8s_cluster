#----------- Private key block ----------#

resource "tls_private_key" "ssh_key_gen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "${var.global_name}_SSH-key"
  public_key = tls_private_key.ssh_key_gen.public_key_openssh
  tags       = var.propper_tags
}

resource "local_file" "ssh_pem_key_file" {
  filename        = "${var.global_name}_id_rsa.pem"
  file_permission = "0600"
  content         = tls_private_key.ssh_key_gen.private_key_pem
}
