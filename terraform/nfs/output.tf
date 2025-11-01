output "instance_info" {
  value = flatten(values(module.instances)[*].instance_outputs)
}
