resource "incus_storage_pool" "pool" {
  for_each = { for i in var.pools : i.name => i }
  name     = each.value.name
  driver   = "btrfs"
  config = {
    size          = each.value.size
    "volume.size" = each.value.volume_size
  }
  lifecycle {
    create_before_destroy = true
  }
}
