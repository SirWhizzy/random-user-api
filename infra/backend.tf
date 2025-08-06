terraform {
  backend "s3" {
    bucket = "terra-backend-files"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}