# main.tf

provider "aws" {
  region = "us-east-1"  # Update to your preferred AWS region
}

# Variables
variable "instance_count" {
  default = 2  # Number of EC2 instances to deploy
}

# Create a custom VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "CustomVPC"
  }
}

# Create a subnet in the custom VPC
resource "aws_subnet" "custom_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"   # Adjust to your desired availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "CustomSubnet"
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name = "CustomIGW"
  }
}

# Create a route table for the VPC
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "CustomRouteTable"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.custom_subnet.id
  route_table_id = aws_route_table.custom_route_table.id
}

# Create a security group to allow HTTP access
resource "aws_security_group" "app_sg" {
  vpc_id      = aws_vpc.custom_vpc.id
  name        = "app_security_group"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP access"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch EC2 instances in the custom subnet
resource "aws_instance" "app_instance" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.custom_subnet.id
  security_groups = [aws_security_group.app_sg.name]

  # User data script to install Docker and run Flask app
  user_data = <<-EOF
              #!/bin/bash
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              INSTANCE_NUMBER=$(printf "%02d" $((${count.index} + 1)))
              docker run -d -e INSTANCE_NUMBER=$INSTANCE_NUMBER -p 5000:5000 <your_docker_image>
              EOF

  tags = {
    Name = "FlaskAppInstance-${count.index + 1}"
  }
}

# Output public IPs of instances
output "instance_ips" {
  value = [for instance in aws_instance.app_instance : instance.public_ip]
}
