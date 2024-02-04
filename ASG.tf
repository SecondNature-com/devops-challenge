resource "aws_launch_template" "example" {
  name_prefix   ="${var.instance_name}_launch_template"
  image_id      = var.image_id
  instance_type = var.instance_type
 // user_data              = filebase64("${path.module}/script.sh")
   user_data     = filebase64("script.sh")
  //user_data = "$filebase64{data.template_file.example.rendered}"
  vpc_security_group_ids            = [aws_security_group.ec2.id]
}

resource "aws_autoscaling_group" "ec2" {
  name               = "${var.instance_name}_auto_scaling_group"
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  health_check_grace_period = 300
  health_check_type    = "EC2"
  vpc_zone_identifier  = [aws_subnet.private.id]
  target_group_arns    = [aws_alb_target_group.ec2.arn]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

data "template_file" "example" {
  template = <<-EOL
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOL
}