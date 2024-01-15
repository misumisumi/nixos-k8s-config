output "pools_info" {
  value = zipmap(
    [for pool in flatten(values(module.pools)) : pool.name],
    [for pool in flatten(values(module.pools)) : {
      remote = pool.remote
      driver = pool.driver
      config = pool.config
    }]
  )
}
