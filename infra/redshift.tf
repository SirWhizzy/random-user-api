
#USERNAME
resource "aws_ssm_parameter" "redshift_db_username" {
  name  = "redshift_db_username"
  type  = "String"
  value = "Tolu"
}

# PASSWORD AND SECRETS
resource "random_password" "redshift_password" {
  length           = 16
  override_special = "()!#$%&_+-={}|" # A list of special characters that will be used in creating the password
  special          = true
  numeric          = true
  upper            = true
}

resource "aws_ssm_parameter" "redshift_db_password" {
  name  = "redshift_db_password"
  type  = "String"
  value = random_password.redshift_password.result
}

# REDSHIFT CLUSTER
resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier        = "randomdata-dev-redshift-cluster"
  database_name             = "random_data_db"
  master_username           = aws_ssm_parameter.redshift_db_username.value
  master_password           = aws_ssm_parameter.redshift_db_password.value
  node_type                 = "ra3.large"
  cluster_type              = "multi-node"
  number_of_nodes           = 2
  publicly_accessible       = true
  port                      = 5439
  encrypted                 = true
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift-subnet-group.name
  vpc_security_group_ids    = [aws_security_group.redshift-security-group.id]
  iam_roles                 = [aws_iam_role.redshift_role.arn]
}


#ROLES AND POLICY
resource "aws_iam_role" "redshift_role" {
  name = "redshift_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "redshift_policy" {
  name = "redshift_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListAllBuckets",
          "redshift:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "redshift_role_policy_attachment" {
  name       = "redshift_role_policy_attachment"
  roles      = [aws_iam_role.redshift_role.name]
  policy_arn = aws_iam_policy.redshift_policy.arn
}

resource "aws_redshift_cluster_iam_roles" "redshift_cluster_iam_roles" {
  cluster_identifier = aws_redshift_cluster.redshift_cluster.cluster_identifier
  iam_role_arns      = [aws_iam_role.redshift_role.arn]
}