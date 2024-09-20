terraform {
  required_providers {
    incus = {
      source = "registry.opentofu.org/lxc/incus"
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

