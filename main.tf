# main.tf

provider "aws" {
  region = "us-east-1"  # Update to your preferred region
}

# Variables
variable "instance_count" {
  default = 2  # Number of EC2 instances to deploy
}

# Retrieve the default VPC
data "aws_vpc" "default" {
  default = true
}

# Create a new subnet within the default VPC
resource "aws_subnet" "default_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"  # Choose an unused CIDR within the VPC range
  availability_zone       = "us-east-1a"   # Update to an availability zone in your region
  map_public_ip_on_launch = true
}

# Create a security group to allow HTTP access
resource "aws_security_group" "app_sg" {
  name        = "app_security_group"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP access"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from all IPs
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

# Launch EC2 instances in the newly created subnet
resource "aws_instance" "app_instance" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.default_subnet.id
  security_groups = [aws_security_group.app_sg.name]

  # User data script to install Docker, run Flask app
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
