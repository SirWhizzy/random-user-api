terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "Dev"
      Project     = "Random User Project"
    }
  }
}