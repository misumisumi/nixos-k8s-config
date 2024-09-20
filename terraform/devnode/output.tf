output "instance_info" {
  value = [for i in libvirt_domain.node : { name = i.name }]
}

