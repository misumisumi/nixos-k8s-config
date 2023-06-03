output "lxd_volume_info" {
  value = values(lxd_volume.volume)[*]
}