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
  ip_protocol       = "tcp"
  to_port           = 5432
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

resource "random_password" "rds-password" {
  length           = 16
  override_special = "()!#$%&_+-={}|"
  special          = true
  numeric          = true
  upper            = true
  lower            = true
}

resource "aws_secretsmanager_secret" "rds-admin-secrets" {
  name                    = "randomuser/dev/rds-admin-credentials/"
  description             = "Admin credentials for the rds cluster"
}

resource "aws_secretsmanager_secret_version" "rds-admin-secrets-version" {
  secret_id = aws_secretsmanager_secret.rds-admin-secrets.id
  secret_string = jsonencode({
    username = "randomuser_rds_admin"
    password = random_password.rds-password.result
  })
}

resource "aws_db_parameter_group" "rds-param-group" {
  name        = "randomuser-rds-parameter-group"
  family      = "postgres16"
  description = "Disable SSL"

}

resource "aws_db_instance" "rds-instance" {
  identifier              = "randomuser-db-instance"
  username                = "randomuser_admin"
  password                = random_password.rds-password.result
  engine                  = "postgres"
  engine_version          = "16.4"
  instance_class          = "db.m5.large"
  db_name                 = "mydb"
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