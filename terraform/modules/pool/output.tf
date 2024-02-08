output "incus_pool_info" {
  value = [for info in values(incus_storage_pool.pool) : {
    name    = info.name
    project = info.project
    remote  = info.remote
  }]
}

