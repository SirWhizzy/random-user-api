terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "Dev"
      Project     = "Random User Project"
    }
  }
}

provider "random" {
  # Configuration options
}