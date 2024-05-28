
provider "aws" {
  region = "ca-central-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2fromami" {
  ami           = "ami-05e86465a5325c170"  # Replace this with your AMI ID
  instance_type = "t2.micro"               # Example instance type, choose according to your requirements
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  tags = {
    Name = "website"  # You can customize the name tag
  }
}

