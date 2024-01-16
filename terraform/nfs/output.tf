output "instance_info" {
  value = flatten(values(module.instances)[*].incus_instance_outputs)
}
