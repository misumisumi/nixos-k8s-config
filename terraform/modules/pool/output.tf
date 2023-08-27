output "lxd_pool_info" {
  value = values(lxd_storage_pool.pool)[*]
}
