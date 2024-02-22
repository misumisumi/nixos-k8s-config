terraform {
  required_providers {
    incus = {
      source  = "registry.terraform.io/lxc/incus"
      version = "~> 0.0.2"
    }
  }
}

resource "incus_volume" "volume" {
  for_each     = { for i in var.volumes : i.name => i }
  remote       = var.remote
  project      = var.project
  config       = each.value.config
  content_type = each.value.content_type
  name         = each.value.name
  pool         = each.value.pool
}

