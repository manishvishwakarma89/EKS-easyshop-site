terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38"   # allows any 6.x >= 6.38
    }
  }
}

