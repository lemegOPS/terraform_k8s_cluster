#----------- IAM Create roles ----------#

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions   = ["s3:Get*", "s3:List*", "s3:Put*"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name               = "K8S_ec2_iam_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "k8s_iam_role_policy" {
  depends_on = [aws_iam_role.ec2_iam_role]
  name       = "K8S_s3_instance_policy"
  role       = aws_iam_role.ec2_iam_role.name
  policy     = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "K8S_iam_instance_profile"
  role = aws_iam_role.ec2_iam_role.name
  tags = var.tags
}