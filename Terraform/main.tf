data "aws_ami" "os_image" {
  owners = ["137112412989"]
  most_recent = true
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/*amd64*"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "bank-app-key"
  public_key = file("bank-app-key.pub")
}

resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "allow_user_to_connect" {
  name        = "allow TLS"
  description = "Allow user to connect"
  vpc_id      = aws_default_vpc.default.id
  ingress {
    description = "port 22 allow ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = " allow all outgoing traffic "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 80 allow"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 443 allow https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bank-app"
  }
}

resource "aws_instance" "testinstance" {
  ami             = data.aws_ami.os_image.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.allow_user_to_connect.name]
  tags = {
    Name = "bank-app-instance"
  }
  root_block_device {
    volume_size = 30 
    volume_type = "gp3"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y apache2",
      "sudo systemctl start apache2",
      "sudo systemctl enable apache2",
      "echo 'Hello from Terraform Provisioners!' | sudo tee /var/www/html/index.html"
    ]
  }
}