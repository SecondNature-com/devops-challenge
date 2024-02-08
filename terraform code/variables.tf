variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "server_port" {
  description = "Server port for the EC2 instances"
  default     = 8080
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  default     = "ami-0c7217cdde317cfec"
}
