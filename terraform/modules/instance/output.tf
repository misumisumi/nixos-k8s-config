output "lxd_instance_outputs" {
  value = values(lxd_instance.instance)[*]
}

output "name" {
  value = values(lxd_instance.instance)[*].name
}

output "ip_address" {
  value = values(lxd_instance.instance)[*].ip_address
}