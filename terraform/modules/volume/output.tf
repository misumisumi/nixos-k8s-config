output "incus_volume_info" {
  value = [for info in values(incus_storage_volume.volume) : {
    name   = info.name
    pool   = info.pool
    remote = info.remote
  }]
}

