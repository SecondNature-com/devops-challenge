# Creating EC2 instance in Public Subnet
resource "aws_instance" "demoinstance" {
  ami                         = "ami-0ecb0bb5d6b19457a"
  instance_type               = "t2.micro"
  key_name                    = "challenge-oregon"
  vpc_security_group_ids      = ["${aws_security_group.demosg.id}"]
  subnet_id                   = "${aws_subnet.demoinstance.id}"
  associate_public_ip_address = true
  user_data                   = "${file("data.sh")}"
tags = {
  Name = "My Public Instance"
  }
}