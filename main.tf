# main.tf

# Provider Configuration
provider "aws" {
  region = "us-west-1"
}

# Variables
variable "server_port" {
  description = "The port on which the web server will listen"
  default     = 8080
}

# EC2 Configuration
resource "aws_instance" "zaga_challenge" {
  ami             = "ami-085284d24fe829cd0"
  instance_type   = "t2.micro"
  user_data       = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF

  tags = {
    Name = "zaga_challenge"
  }
}

# VPC Configuration
module "vpc" {
  source = "./modules/vpc"
  # Include necessary variables for the VPC module
}

# ALB Configuration
resource "aws_lb" "zaga_alb" {
  name               = "zaga-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.default_security_group_id]

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  subnets = module.vpc.public_subnets

  enable_http2               = true
  idle_timeout               = 400
  enable_deletion_protection = false

  enable_deletion_protection = false
  enable_http_drop_cookie    = false

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  enable_deletion_protection = false
  enable_http2               = true
}

# CI/CD Configuration
resource "aws_s3_bucket" "zaga_s3_bucket" {
  bucket = "zaga-s3-bucket"
  acl    = "public-read"
}

resource "aws_codepipeline" "zaga_pipeline" {
  name     = "zaga-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.zaga_s3_bucket.bucket
    type     = "S3"
  }

  stages {
    name = "Source"

    actions {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner             = "pavani4842@gmail.com"
        Repo              = "zaga_challenge"
        Branch            = "main"
        OAuthToken        = var.github_oauth_token
        PollForSourceChanges = true
      }
    }
  }

  stages {
    name = "Deploy"

    actions {
      name            = "DeployAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.zaga_codebuild.name
      }
    }
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_role"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "codepipeline.amazonaws.com"
          }
        }
      ]
    }
  EOF
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "codebuild.amazonaws.com"
          }
        }
      ]
    }
  EOF
}

# IAM Policy for CodePipeline Role
resource "aws_iam_policy" "codepipeline_policy" {
  name        = "codepipeline_policy"
  description = "IAM policy for CodePipeline role"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:CreateBucket",
            "s3:PutObject"
          ],
          "Resource": [
            "${aws_s3_bucket.zaga_s3_bucket.arn}",
            "${aws_s3_bucket.zaga_s3_bucket.arn}/*"
          ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
          ],
          "Resource": "*"
        }
      ]
    }
  EOF
}

# IAM Policy for CodeBuild Role
resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild_policy"
  description = "IAM policy for CodeBuild role"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:CreateBucket",
            "s3:PutObject"
          ],
          "Resource": [
            "${aws_s3_bucket.zaga_s3_bucket.arn}",
            "${aws_s3_bucket.zaga_s3_bucket.arn}/*"
          ]
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# CodeBuild Project
resource "aws_codebuild_project" "zaga_codebuild" {
  name        = "zaga-codebuild"
  description = "CodeBuild project for Zaga Challenge"
  build_timeout = "5"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard
