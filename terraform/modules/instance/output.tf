output "instance_outputs" {
  value = [for info in values(incus_instance.instance) : {
    name         = info.name,
    mac_address  = info.mac_address,
    ipv4_address = info.ipv4_address,
    ipv6_address = info.ipv6_address,
    host_id      = random_id.host_id[info.name].hex
  }]
}
