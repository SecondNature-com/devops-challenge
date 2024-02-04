resource "aws_lb" "test" {
  name               = "${var.instance_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public1.id]

 // enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# Target group
resource "aws_alb_target_group" "ec2" {
  name     = "${var.instance_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  health_check {
    path                = "/"
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 60
    matcher             = "200"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.ec2.id
  lb_target_group_arn    = aws_alb_target_group.ec2.arn
}

resource "aws_alb_listener" "ec2-alb-http-listener" {
  load_balancer_arn = aws_lb.test.id
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.ec2]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ec2.arn
  }
}