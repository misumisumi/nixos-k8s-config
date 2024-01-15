output "incus_pool_info" {
  value = values(incus_storage_pool.pool)[*]
}
