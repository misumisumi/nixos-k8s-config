# terraform init
# terraform apply -auto-approve
# terraform destroy -auto-approve


terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

provider "lxd" {
  generate_client_certificates = true
  accept_remote_certificate    = true
}

resource "lxd_container" "nixos-master" {
  name  = "nixos-master"
  image = "nixos"

  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu = 2
    memory = "2GB"
  }
}
resource "lxd_container" "nixos-node" {
  name  = "nixos-node"
  image = "nixos"

  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu = 2
    memory = "2GB"
  }
}