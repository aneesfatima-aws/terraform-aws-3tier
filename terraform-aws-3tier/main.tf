
resource "aws_vpc" "main" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lab4-vpc"
  }
}


resource "aws_subnet" "public1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "us-east-1a"

  map_public_ip_on_launch = true
}


resource "aws_subnet" "public2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.2.0/24"

  availability_zone = "us-east-1b"

  map_public_ip_on_launch = true
}



resource "aws_subnet" "private1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.3.0/24"

  availability_zone = "us-east-1a"
}



resource "aws_subnet" "private2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.4.0/24"

  availability_zone = "us-east-1b"
}



resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id
}



resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }
}


resource "aws_route_table_association" "pub1" {

  subnet_id = aws_subnet.public1.id

  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub2" {

  subnet_id = aws_subnet.public2.id

  route_table_id = aws_route_table.public_rt.id
}


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


resource "aws_instance" "app" {

  ami = "ami-0c02fb55956c7d316"

  instance_type = var.instance_type

  subnet_id = aws_subnet.public1.id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = file("userdata.sh")

  tags = {
    Name = "Lab4-App-Server"
  }
}


resource "aws_lb_target_group" "tg" {

  name = "lab4-target-group"

  port = 80

  protocol = "HTTP"

  vpc_id = aws_vpc.main.id
}


resource "aws_lb_target_group_attachment" "attach" {

  target_group_arn = aws_lb_target_group.tg.arn

  target_id = aws_instance.app.id

  port = 80
}


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


resource "aws_lb_listener" "listener" {

  load_balancer_arn = aws_lb.alb.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.tg.arn
  }
}


resource "aws_db_subnet_group" "db_subnet" {

  name = "lab4-db-subnet"

  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
}


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

