#!/bin/bash
sudo yum install httpd -y
sudo echo "Hello, World" > /var/www/html/index.html
systemctl start httpd 
systemctl enable httpd