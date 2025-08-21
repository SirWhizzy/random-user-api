# vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tolu-vpc"
  }
}

# Public subnet 1
resource "aws_subnet" "public-subnet-a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "randomuser-pub-subnet-a"
  }
}

# Public subnet 2
resource "aws_subnet" "public-subnet-b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "randomuser-pub-subnet-b"
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "randomuser-igw"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "randomuser-pub-rt"
  }
}

resource "aws_route_table_association" "pub_rt_assoc_a" {
  subnet_id      = aws_subnet.public-subnet-a.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "pub_rt_assoc_b" {
  subnet_id      = aws_subnet.public-subnet-b.id
  route_table_id = aws_route_table.public-route-table.id
}


# SECURITY GROUP CONFIG
resource "aws_security_group" "redshift-security-group" {
  name   = "randomdata-redshift-sg"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "redshift-ingress-rule" {
  security_group_id = aws_security_group.redshift-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5439
  to_port           = 5439
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "redshift-egress-rule" {
  security_group_id = aws_security_group.redshift-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# SUBNET GROUP
resource "aws_redshift_subnet_group" "redshift-subnet-group" {
  name       = "randomdata-dev-redshift-subnet-group"
  subnet_ids = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]
}

#PARAMTER GROUP
resource "aws_redshift_parameter_group" "redshift_parameter_group" {
  name   = "redshift-parameter-group"
  family = "redshift-2.0"

  parameter {
    name  = "require_ssl"
    value = "false"
  }
}