provider "aws" {
  region = "us-east-1"
  shared_config_files      = ["/root/.aws/config"]
  shared_credentials_files = ["/root/.aws/credentials"]
}
