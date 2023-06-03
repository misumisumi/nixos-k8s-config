output "dev_pool_info" {
  value = values(lxd_storage_pool.dev_pool)[*]
}