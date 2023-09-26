output "lxd_instance_outputs" {
  value = [for info in values(lxd_instance.instance) : {
    name       = info.name,
    ip_address = info.ip_address,
    host_id    = random_id.host_id[info.name].hex
  }]
}
