# PASSWORD AND SECRETS
resource "random_password" "redshift-password" {
  length           = 16
  override_special = "()!#$%&_+-={}|" # A list of special characters that will be used in creating the password
  special          = true
  numeric          = true
  upper            = true
  lower            = true
}

resource "aws_secretsmanager_secret" "redshift-admin-secrets" {
  name                    = "randomuser/dev/redshift-admin-creds/"
  description             = "Admin credentials for the redshift cluster"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "redshift_admin_secrets_version" {
  secret_id = aws_secretsmanager_secret.redshift-admin-secrets.id
  secret_string = jsonencode({
    username = "randomuser-redshift-admin"
    password = random_password.redshift-password.result
  })
}


# SECURITY GROUP CONFIG
resource "aws_security_group" "redshift-security-group" {
  name   = "randomuser-redshift-sg"
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
  name       = "randomuser-dev-redshift-subnet-group"
  subnet_ids = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-b.id]
}


# CLUSTER
resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier           = "randomuser-dev-redshift-cluster"
  database_name                = "random_user_db"
  master_username              = "randomuser-redshift-admin"
  master_password              = random_password.redshift-password.result
  node_type                    = "ra3.large"
  cluster_type                 = "multi-node"
  number_of_nodes              = 2
  publicly_accessible          = true
  port                         = 5439
  encrypted                    = true
  cluster_subnet_group_name    = aws_redshift_subnet_group.redshift-subnet-group.name
  vpc_security_group_ids       = [aws_security_group.redshift-security-group.id]
  skip_final_snapshot          = true
  cluster_parameter_group_name = aws_redshift_parameter_group.redshfit-param-group.name
}