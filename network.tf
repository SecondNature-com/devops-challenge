resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.example.id
  cidr_block = var.subnet_cidr[0]
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.example.id
  cidr_block = var.subnet_cidr[1]
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "public1"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.example.id
  cidr_block = var.subnet_cidr[2]
  availability_zone = var.availability_zones[2]

  tags = {
    Name = "private"
  }
}

# NAT Gateway for the public subnet
resource "aws_eip" "nat_gateway" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"
  depends_on                = [aws_internet_gateway.example]
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "terraform"
  }
  depends_on = [aws_eip.nat_gateway]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "private"
  }
}

# Route the public subnet traffic through the Internet Gateway
resource "aws_route" "public-igw-route" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

# Route NAT Gateway
resource "aws_route" "nat-gw-route" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}


resource "aws_route_table_association" "public-asso" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    description = "TLS from VPC"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# Instance Security group (traffic ALB -> EC2, ssh -> EC2)
resource "aws_security_group" "ec2" {
  name        = "ec2_security_group"
  description = "Allows inbound access from the ALB only"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "main"
  }
}