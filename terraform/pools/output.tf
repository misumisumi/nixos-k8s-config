output "pools_info" {
  value = zipmap(
    [for name in flatten(keys(incus_storage_pool.pools)) : name],
    [for pool in flatten(values(incus_storage_pool.pools)) : {
      remote = pool.remote
      project = pool.project
      driver = pool.driver
      config = pool.config
    }]
  )
}
