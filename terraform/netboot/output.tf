output "instance_info" {
  value = flatten(values(module.instances)[*].lxd_instance_outputs)
}
