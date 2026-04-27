# --------------------
# VPC
# --------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "kondal-vpc"
  }
}

# --------------------
# Internet Gateway
# --------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "kondal-igw"
  }
}

# --------------------
# Subnets
# --------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "kondal-public-subnet"
  }
}

resource "aws_subnet" "private_backend" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "kondal-private-backend-subnet"
  }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "kondal-private-db-subnet"
  }
}
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

# --------------------
# Public Route Table
# --------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "kondal-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# --------------------
# Elastic IP for NAT Gateway
# --------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "kondal-nat-eip"
  }
}

# --------------------
# NAT Gateway in Public Subnet
# --------------------
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "kondal-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# --------------------
# Private Route Table
# --------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "kondal-private-rt"
  }
}

resource "aws_route_table_association" "private_backend_assoc" {
  subnet_id      = aws_subnet.private_backend.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_db_assoc" {
  subnet_id      = aws_subnet.private_db.id
  route_table_id = aws_route_table.private_rt.id
}
