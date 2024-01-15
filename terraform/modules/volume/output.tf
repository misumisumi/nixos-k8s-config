output "incus_volume_info" {
  value = values(incus_volume.volume)[*]
}
