provider "aws" {
  region     = var.region
  
}

# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.3.0"

  name = "zaga-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true
}

# EC2 Auto Scaling Group and Load Balancer Configuration
resource "aws_launch_configuration" "lc" {
  name_prefix   = "lc-zaga-"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration      = aws_launch_configuration.lc.id
  vpc_zone_identifier       = module.vpc.public_subnets
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "EC2"
  force_delete              = true
  wait_for_capacity_timeout = "0"
}

resource "aws_lb" "zaga_alb" {
  name               = "zaga-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.zaga_alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_security_group" "zaga_alb_sg" {
  name        = "zaga-alb-sg"
  description = "Security group for Zaga ALB"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
