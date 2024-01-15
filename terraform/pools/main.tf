terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 1.10.4"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  dynamic "lxd_remote" {
    for_each = var.remote_hosts
    content {
      name    = lxd_remote.value.name
      address = lxd_remote.value.address
      scheme  = "https"
    }
  }
}

# Only use making env label for outputing show.json to use from colmena
resource "terraform_data" "workspace" {
  input = terraform.workspace
}

module "pools" {
  source = "../modules/pool"
  pools  = var.pools
}
