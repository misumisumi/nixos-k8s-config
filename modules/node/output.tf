output "lxd_container_outputs" {
  value = values(lxd_container.node)[*]
}

output "name" {
  value = values(lxd_container.node)[*].name
}

output "ip_address" {
  value = values(lxd_container.node)[*].ip_address
}