output "lxd_instance_outputs" {
  value = values(lxd_instance.node)[*]
}

output "name" {
  value = values(lxd_instance.node)[*].name
}

output "ip_address" {
  value = values(lxd_instance.node)[*].ip_address
}
