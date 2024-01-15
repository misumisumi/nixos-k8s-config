resource "incus_volume" "volume" {
  for_each     = { for i in var.volumes : i.name => i }
  name         = each.value.name
  remote       = each.value.remote
  pool         = each.value.pool
  content_type = each.value.content_type
}
