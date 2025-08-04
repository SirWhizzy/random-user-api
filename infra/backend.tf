terraform {
  backend "s3" {
    bucket = "api-infra"
    key    = "dev/terraform.tfstate"
    region = "eu-north-1"
  }
}