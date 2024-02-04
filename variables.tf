variable "server_port" {
  type    = string
  default = 8080
}

variable "instance_name" {
  type    = string
  default = "devops-challenge"
}



variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "subnet_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}



variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "image_id" {
  type    = string
  default = "ami-0277155c3f0ab2930"
}

