terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
 
  # Uncomment after running bootstrap
  backend "s3" {
     bucket          = "prod-base-project-terraform-state-prod"
     key            = "terraform.tfstate"
     region         = "ap-south-1"
     dynamodb_table = "prod-base-project-terraform-locks-prod"
     encrypt        = true
   }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
