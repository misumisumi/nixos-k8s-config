output "cluster_info" {
  value = zipmap(
    keys(module.cluster),
    [for nodes in values(module.cluster) : zipmap(nodes.name, nodes.ip_address)]
  )
}
