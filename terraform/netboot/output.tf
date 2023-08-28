output "cluster_info" {
  value = zipmap(
    keys(module.instances),
    [for instance in values(module.instances) : zipmap(instance.name, instance.ip_address)]
  )
}