terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_volume" "volume" {
  for_each = { for i in var.volumes : i.name => i }
  name     = each.value.name
  pool     = each.value.pool
  # content_type = each.value.content_type
}
