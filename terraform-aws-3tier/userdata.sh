#!/bin/bash

yum update -y

yum install -y httpd php php-mysqlnd

systemctl start httpd
systemctl enable httpd

echo "<h1>Lab 4 AWS 3-Tier Architecture</h1>" > /var/www/html/index.html

