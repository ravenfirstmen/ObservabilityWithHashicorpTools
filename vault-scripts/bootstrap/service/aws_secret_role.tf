resource "vault_aws_secret_backend_role" "aws" {
  backend         = var.aws_secrets_path
  name            = var.service_name
  credential_type = "assumed_role"
  role_arns       = ["arn-something"]
}