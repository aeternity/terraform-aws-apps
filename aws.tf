terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.4"
    }

    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "2.0.0-beta.3"
    }
  }

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
