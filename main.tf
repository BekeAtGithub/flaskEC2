# main.tf

provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# Variables
variable "instance_count" {
  default = 2  # Number of EC2 instances to deploy
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

# Launch EC2 instances
resource "aws_instance" "app_instance" {
  count         = var.instance_count
  ami           = "ami-0230bd60aa48260c6"  # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  security_groups = [aws_security_group.app_sg.name]

  # User data script to install Docker, run Flask app
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              
              # Pull and run Docker container with INSTANCE_NUMBER
              INSTANCE_NUMBER=$(printf "%02d" $((${count.index} + 1)))
              docker run -d -e INSTANCE_NUMBER=$INSTANCE_NUMBER -p 5000:5000 <your_docker_image>
              EOF

  tags = {
    Name = "FlaskAppInstance-${count.index + 1}"
  }
}

# Output instance information
output "instance_ips" {
  value = [for instance in aws_instance.app_instance : instance.public_ip]
}
