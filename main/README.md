# Terraform Configuration

Every terraform workspace variable file should have the terraform variable defined with the `required_version`, `backend` and `required_providers` fields to store the Terraform state file remotely.

Example 01:

    terraform = {
        required_version = ">= 0.13"
        backend = {
            s3 = {
                bucket  = "terraformstate-8114-2576-4213"
                key     = "dev/terraform.tfstate"
                encrypt = true
                region  = "ap-southeast-1"
                dynamodb_table = "terraform"
            }
        }
        required_providers = {
            aws = {
                source  = "hashicorp/aws"
                version = ">= 1.0"
            }
            azurerm = ">= 2.0"
        }
    }

Example 02:

    terraform {
        backend = {
            remote = {
                hostname = "app.terraform.io"
                organization = "company"

                workspaces = {
                    prefix = "my-app-"
                }
            }
        }
    }

Example 03:

    terraform = {
        backend = {
            azurerm = {
                resource_group_name  = "StorageAccount-ResourceGroup"
                storage_account_name = "abcd1234"
                container_name       = "tfstate"
                key                  = "prod.terraform.tfstate"
            }
        }
    }

