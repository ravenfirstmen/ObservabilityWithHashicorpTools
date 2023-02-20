data "local_file" "ca_private_key" {
  filename = var.ca_private_key_file
}

data "local_file" "ca_public_key" {
  filename = var.ca_public_key_file
}

locals {
  ca_certificate_data = {
    cert = data.local_file.ca_public_key.content_base64
    key  = data.local_file.ca_private_key.content_base64
  }
}

locals {
  ca_certificate = base64encode(jsonencode(local.ca_certificate_data))
}