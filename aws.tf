terraform {
  backend "s3" {
    bucket         = "aeternity-terraform-states"
    key            = "ae-apps.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "eu-central-1"
}
