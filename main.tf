provider "aws" {
  profile = "default"
  region = "us-west-2"
  default_tags {
    tags = {
      Name = "sn_challenge"
    }
  }
}

locals {
    app_port      = 8080
    http_port     = 80
    ami           = "ami-0eb199b995e2bc4e3"
    instance_type = "t2.micro"
    min_size      = 1
    max_size      = 1
}

module "temp_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "sn_vpc"
  cidr = "192.168.0.0/24"

  azs             = ["us-west-2a", "us-west-2c"]
  private_subnets = ["192.168.0.0/26", "192.168.0.64/26"]
  public_subnets  = ["192.168.0.128/26", "192.168.0.192/26"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

}

data "template_file" "sn_user_data"{
  template = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${local.app_port} &
    EOF
}
resource "aws_security_group" "sn_alb_sg" {
  name        = "sn_alb_SG"
  description = "Allows access via 80"
  vpc_id      = module.temp_vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "sn_alb_sg_egress" {
  security_group_id = aws_security_group.sn_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "sn_alb_sg_ingress" {
  security_group_id = aws_security_group.sn_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = local.http_port
  ip_protocol       = "tcp"
  to_port           = local.http_port
}

resource "aws_security_group" "sn_app_sg" {
  name        = "sn_app_SG"
  description = "Allows access via 80"
  vpc_id      = module.temp_vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "sn_app_sg_egress" {
  security_group_id = aws_security_group.sn_app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "sn_app_sg_ingress" {
  security_group_id = aws_security_group.sn_app_sg.id
  cidr_ipv4         = module.temp_vpc.vpc_cidr_block
  from_port         = local.app_port
  ip_protocol       = "tcp"
  to_port           = local.app_port
}

resource "aws_lb" "sn_alb" {
  name               = "sn-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sn_alb_sg.id] 
  subnets            = [for subnet in module.temp_vpc.public_subnets : subnet]
}

resource "aws_lb_target_group" "sn_tg" {
  name        = "sn-target-group"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.temp_vpc.vpc_id  
}

resource "aws_alb_listener" "sn_alb_listener" {
  load_balancer_arn = aws_lb.sn_alb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sn_tg.arn
  }
}

resource "aws_launch_template" "sn_launch_template" {
  name                   = "sn_launch_template"
  image_id               = local.ami
  instance_type          = local.instance_type
  vpc_security_group_ids = [aws_security_group.sn_app_sg.id]
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs         {
    encrypted             = true
    delete_on_termination = true
    volume_type           = "gp3"
    }
  }
  user_data = "${base64encode(data.template_file.sn_user_data.rendered)}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sn_autoscaling_group" {
  name_prefix         = "sn_ASG-"
  vpc_zone_identifier = [for subnet in module.temp_vpc.private_subnets : subnet]
  desired_capacity    = local.min_size
  min_size            = local.min_size
  max_size            = local.max_size
  
  launch_template {
    id      = aws_launch_template.sn_launch_template.id 
    version = aws_launch_template.sn_launch_template.latest_version
  }
  target_group_arns = [aws_lb_target_group.sn_tg.arn]
}
