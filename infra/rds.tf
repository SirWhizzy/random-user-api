# RDS security group
resource "aws_security_group" "rds-security-group" {
  name        = "randomuser-security-group"
  description = "Security Group"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "rds-ingress-rule" {
  security_group_id = aws_security_group.rds-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rds-egress-rule" {
  security_group_id = aws_security_group.rds-security-group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS subnet group
resource "aws_db_subnet_group" "rds-subnet-group" {
  name = "randomuser-rds-subnet-group"
  subnet_ids = [
    aws_subnet.public-subnet-a.id,
    aws_subnet.public-subnet-b.id
  ]
}


#USERNAME
resource "aws_ssm_parameter" "rds_db_username" {
  name  = "rds_db_username"
  type  = "String"
  value = "rds_user"
}

#PASSWORD
resource "random_password" "rds_db_password" {
  length           = 12
  numeric          = true
  upper            = true
  lower            = true
}

resource "aws_ssm_parameter" "rds_db_password" {
  name  = "rds_db_password"
  type  = "String"
  value = random_password.rds_db_password.result
}


resource "aws_db_parameter_group" "rds-param-group" {
  name        = "randomuser-rds-parameter-group"
  family      = "postgres16"
  description = "Disable SSL"
}

resource "aws_db_instance" "rds-instance" {
  identifier              = "randomuser-db-instance"
  username                = aws_ssm_parameter.rds_db_username.value
  password                = aws_ssm_parameter.rds_db_password.value
  engine                  = "postgres"
  engine_version          = "16.4"
  instance_class          = "db.m5.large"
  db_name                 = "random_user"
  port                    = 5432
  publicly_accessible     = true
  allocated_storage       = 30
  apply_immediately       = true
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true
  parameter_group_name    = aws_db_parameter_group.rds-param-group.name
  vpc_security_group_ids  = [aws_security_group.rds-security-group.id]
  db_subnet_group_name    = aws_db_subnet_group.rds-subnet-group.name
}