provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = var.skip_credentials_validation
  skip_requesting_account_id  = var.skip_requesting_account_id
  skip_metadata_api_check     = var.skip_metadata_api_check
  skip_region_validation      = var.skip_region_validation
  default_tags {
    tags = var.common_tags
  }
}