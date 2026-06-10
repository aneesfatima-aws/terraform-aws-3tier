# terraform-aws-3tier
<img width="1536" height="1024" alt="WhatsApp Image 2026-06-02 at 2 30 59 AM" src="https://github.com/user-attachments/assets/64a53360-cc63-4230-9091-19548b456007" />

LAB 4 — AWS 3-Tier Architecture using Terraform

FINAL ARCHITECTURE

Internet
    |
    v
Application Load Balancer (Public Subnets)
    |
    v
EC2 Application Server (Private Subnets)
    |
    v
RDS MySQL Database (Private Subnets)


---

WHAT YOU WILL CREATE

Networking

✅ VPC
✅ 2 Public Subnets
✅ 2 Private Subnets
✅ Internet Gateway
✅ Route Tables

Security

✅ ALB Security Group
✅ EC2 Security Group
✅ RDS Security Group

Compute

✅ EC2 Instance
✅ Apache + PHP App

Load Balancing

✅ Application Load Balancer
✅ Target Group
✅ Listener

Database

✅ RDS MySQL
✅ DB Subnet Group


---

PROJECT STRUCTURE

Create folder:

terraform-aws-3tier
│
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── main.tf
├── outputs.tf
└── userdata.sh


---

## STEP 1 — provider.tf

Create file:

```provider "aws" {
  region = var.region
}

```
---

## STEP 2 — variables.tf

```variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "Password123!"
}
```

---

## STEP 3 — terraform.tfvars

```region        = "us-east-1"
instance_type = "t2.micro"

db_username = "admin"
db_password = "Password123!"

```
---

## STEP 4 — userdata.sh

Create:

```#!/bin/bash

yum update -y

yum install -y httpd php php-mysqlnd

systemctl start httpd
systemctl enable httpd

echo "<h1>Lab 4 AWS 3-Tier Architecture</h1>" > /var/www/html/index.html

```
---

## STEP 5 — main.tf

NOW paste EVERYTHING below inside main.tf

```VPC

resource "aws_vpc" "main" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lab4-vpc"
  }
}
```

---

```PUBLIC SUBNET 1

resource "aws_subnet" "public1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true
}

```
---

```PUBLIC SUBNET 2

resource "aws_subnet" "public2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.2.0/24"

  availability_zone = "us-east-1b"

  map_public_ip_on_launch = true
}

```
---

```PRIVATE SUBNET 1

resource "aws_subnet" "private1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.3.0/24"

  availability_zone = "us-east-1a"
}
```

---

```PRIVATE SUBNET 2

resource "aws_subnet" "private2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.4.0/24"

  availability_zone = "us-east-1b"
}
```

---

```INTERNET GATEWAY

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id
}
```

---

```ROUTE TABLE

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }
}
```

---

```ROUTE TABLE ASSOCIATIONS

resource "aws_route_table_association" "pub1" {

  subnet_id = aws_subnet.public1.id

  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub2" {

  subnet_id = aws_subnet.public2.id

  route_table_id = aws_route_table.public_rt.id
}
```

---

```ALB SECURITY GROUP

resource "aws_security_group" "alb_sg" {

  name = "alb-sg"

  vpc_id = aws_vpc.main.id

  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

```EC2 SECURITY GROUP

resource "aws_security_group" "ec2_sg" {

  name = "ec2-sg"

  vpc_id = aws_vpc.main.id

  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

```RDS SECURITY GROUP

resource "aws_security_group" "rds_sg" {

  name = "rds-sg"

  vpc_id = aws_vpc.main.id

  ingress {

    from_port = 3306

    to_port = 3306

    protocol = "tcp"

    security_groups = [aws_security_group.ec2_sg.id]
  }
}
```

---

```EC2 INSTANCE

resource "aws_instance" "app" {

  ami = "ami-0c02fb55956c7d316"

  instance_type = var.instance_type

  subnet_id = aws_public_subnet.public1.id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = file("userdata.sh")

  tags = {
    Name = "Lab4-App-Server"
  }
}
```
⚠️ IMPORTANT:

If error aaye:

`aws_public_subnet.public1`

Then replace with:

`aws_subnet.public1.id`


---

```TARGET GROUP

resource "aws_lb_target_group" "tg" {

  name = "lab4-target-group"

  port = 80

  protocol = "HTTP"

  vpc_id = aws_vpc.main.id
}
```

---

```ATTACH EC2 TO TARGET GROUP

resource "aws_lb_target_group_attachment" "attach" {

  target_group_arn = aws_lb_target_group.tg.arn

  target_id = aws_instance.app.id

  port = 80
}

```
---

```APPLICATION LOAD BALANCER

resource "aws_lb" "alb" {

  name = "lab4-alb"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
}
```

---

```LISTENER

resource "aws_lb_listener" "listener" {

  load_balancer_arn = aws_lb.alb.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.tg.arn
  }
}
```

---

```DB SUBNET GROUP

resource "aws_db_subnet_group" "db_subnet" {

  name = "lab4-db-subnet"

  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
}

```
---

```RDS MYSQL

resource "aws_db_instance" "mysql" {

  allocated_storage = 20

  engine = "mysql"

  instance_class = "db.t3.micro"

  username = var.db_username

  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.db_subnet.name

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  skip_final_snapshot = true
}
```

---

## STEP 6 — outputs.tf

```output "alb_dns_name" {

  value = aws_lb.alb.dns_name
}

output "ec2_public_ip" {

  value = aws_instance.app.public_ip
}

output "rds_endpoint" {

  value = aws_db_instance.mysql.endpoint
}

```
---

## STEP 7 — TERRAFORM COMMANDS

Initialize

`terraform init`


---

Validate

`terraform validate`


---

Plan

`terraform plan`


---

Deploy

`terraform apply`

Type:

`yes`


---

## STEP 8 — TEST

After apply:

terraform output

Copy:

`alb_dns_name`

`Open in browser.`

You should see:

`Lab 4 AWS 3-Tier Architecture`


---

## WHAT THIS LAB TAUGHT YOU

- ✅ VPC Networking
- ✅ Public vs Private Subnets
- ✅ ALB
- ✅ EC2
- ✅ RDS
- ✅ Security Groups
- ✅ Terraform Infrastructure Automation
- ✅ 3-Tier Architecture Design
- ✅ Cloud Security Layering
