provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "demo-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    instance_tenancy = "default"

    tags = {
        Name = "demo-vpc"
    }
}

resource "aws_subnet" "demo-subnet-private" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "false" //it makes this a private subnet
    availability_zone = "us-east-1a"

    tags = {
        Name = "demo-subnet-private"
    }
}

resource "aws_subnet" "demo-public-subnets" {
  count             = length(var.subnet_cidr_public)
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = var.subnet_cidr_public[count.index]
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone = var.availability_zone[count.index]
  
}

# create an IGW (Internet Gateway)
# It enables your vpc to connect to the internet
resource "aws_internet_gateway" "demo-igw" {
    vpc_id = "${aws_vpc.demo-vpc.id}"

    tags = {
        Name = "demo-igw"
    }
}

# create a custom route table for public subnets
# public subnets can reach to the internet by using this
resource "aws_route_table" "demo-public-crt" {
    vpc_id = "${aws_vpc.demo-vpc.id}"
    route {
        cidr_block = "0.0.0.0/0" //associated subnet can reach everywhere
        gateway_id = "${aws_internet_gateway.demo-igw.id}" //CRT uses this IGW to reach internet
    }

    tags = {
        Name = "demo-public-crt"
    }
}

# route table association for the public subnets
resource "aws_route_table_association" "demo-crta-public-subnet" {
	count = length(var.subnet_cidr_public)
    subnet_id = element(aws_subnet.demo-public-subnets.*.id, count.index)
    route_table_id = "${aws_route_table.demo-public-crt.id}"
}

# security group

resource "aws_security_group" "demo-sg" {

    vpc_id = "${aws_vpc.demo-vpc.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        
        // This means, all ip address are allowed to ssh !
        // Do not do it in the production. Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }

    //If you do not add this rule, you can not reach the NGIX
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "demo-sg"
    }
}

resource "aws_instance" "demo-instance" {

	count = length(var.subnet_cidr_public)

    ami = "${var.AMI}"
    instance_type = "t2.micro"

    # VPC
    subnet_id = element(aws_subnet.demo-public-subnets.*.id, count.index)

    # Security Group
    vpc_security_group_ids = ["${aws_security_group.demo-sg.id}"]

    # the Public SSH key
    key_name = "${var.KEY_NAME}"

    connection {
        user = "${var.EC2_USER}"
        private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    }
	
	tags = {
        Name = "demo-instance"
    }
}

resource "aws_lb_target_group" "demo-tg" {
  name     = "demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.demo-vpc.id}"
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "demo-attach-app" {
  count            = length(aws_instance.demo-instance)
  target_group_arn = aws_lb_target_group.demo-tg.arn
  target_id        = element(aws_instance.demo-instance.*.id, count.index)
  port             = 80
}

resource "aws_lb" "demo-alb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo-sg.id]
  subnets            = [for subnet in aws_subnet.demo-public-subnets : subnet.id]

  enable_deletion_protection = false

}

resource "aws_lb_listener" "demo-listener" {
  load_balancer_arn = aws_lb.demo-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo-tg.arn
  }
}
