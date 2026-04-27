data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "kondal-frontend"
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_backend.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "kondal-backend"
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_db.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_name

  tags = {
    Name = "kondal-db"
  }
}
