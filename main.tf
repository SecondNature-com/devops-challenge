provider "aws" {
  region = "us-west-1"
}

resource "aws_instance" "zaga_challenge" {
  ami	        = "ami-085284d24fe829cd0"
  instance_type = "t2.micro"
  tags = {
    Name = "zaga_challenge"
  }
}
