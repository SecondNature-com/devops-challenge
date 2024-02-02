# DevOps Challenge

## Introduction

This challenge is for a candidate who is passionate about DevOps and has strong competency with both AWS and Terraform.

We are not aiming to take too much of your personal time for this challenge. We expect to see how you approach the problem and how you can solve it, and not the most perfect written code in
a `tf` file nor a too complicated Pipeline. Please don't spend more than a couple of hours on this challenge.

We are breaking the challenge in two pieces, one for a piece of Terraform code that could set up an Auto Scaling Group
(ASG) of web servers that deliver a website from a load balancer; and the second piece is a manual process to
configure a CI/CD Pipeline using AWS CodePipeline. 

Instructions below:

#### EC2 Configuration

First, create a fork of this repository to your personal GitHub account. All work should be done in your personal repository.

A starting point can be found in the [main terraform file](main.tf). The AMI used is included in the Free Tier.
There is no need to run a specific web server, and instead you can use `busybox` to run a server as soon as your
instance launches for the first time:

```bash
<<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF
```

Please be aware that the `aws_instance` resource will not necessarily be part of the final script.

> :warning: Make sure to have `8080` as your `server_port` variable.

Please feel free to use any other approach here.

#### VPC Configuration

It is allowed to use [terraform modules](https://github.com/terraform-aws-modules/terraform-aws-vpc) for this. Subnets
with multiple AZs would be needed.

#### ALB Configuration

This is intended to manage traffic. The website is publicly accessible via the ALB, and should not be publicly
accessible unless going through the ALB.

#### Documentation

Please document your `tf` file(s).

#### CI/CD Configuration

You will set up an S3 bucket and a CodePipeline. The Pipeline will be used to deploy a static
website with a very basic HTML page. 

Please create a repository containing a single file called `index.html` with the following content:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport"
      content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Zaga Challenge</title>
  </head>
  <body>
    <h1>Hello, World!</h1>
  </body>
</html>
```

Some proposed steps:

- Create an S3 bucket
- Create a CodePipeline
- Update the bucket permissions to allow public access
- Test the Pipeline by pushing some changes to your repository

> :warning: When ready, please grant access to your repo to [mitchell-bu](https://github.com/mitchell-bu) and [zoix](https://github.com/zoix), so they can push and
> test the Pipeline.

## Bonus Points

- Use Packer to create an AMI that we can reuse
- Use more variables other than the `server_port` so this can be used in different applications
- Include an `output` message to get the DNS name that we can use to see the result
- Use the Pipeline to have a development environment and a production environment

## How to Submit your Challenge

You would need to have an AWS Free Tier account, and we do not need to have access.

Please create a PR with an overview of what you have accomplished, including the DNS name for the ALB, the S3 URI, and
any other information that you consider relevant to share. Be sure to add [mitchell-bu](https://github.com/mitchell-bu) and [zoix](https://github.com/zoix) and reviewers to the PR.

Finally, please specify how much of your time you spent on this challenge. This won't necessarily affect your score, and
will be used internally to adjust this and any other test.

You optionally can include the necessary steps to run your solution.
