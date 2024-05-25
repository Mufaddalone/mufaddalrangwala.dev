provider "aws" {
  region = "us-west-1"
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

resource "aws_instance" "example" {
  ami           = "ami-08012c0a9ee8e21c4"  # Change to your preferred AMI ID
  instance_type = "t2.micro"
  key_name      = "website"  # Reference the existing key pair name

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "website"
  }
}
