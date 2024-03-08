output "devnodes" {
  value = [for i in libvirt_domain.node : i.name]
}

