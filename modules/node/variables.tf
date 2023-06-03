variable "name" {
  type        = string
  description = "Base name for the machine and boot volume"
}

variable "nodes" {
  type = set(
    object({
      name       = string
      target     = string
      ip_address = string
      devices = set(
        object({
          name       = string
          type       = string
          properties = map(string)
      }))
    })
  )
  description = "Name to give to each nodes"
}

variable "node_rd" {
  type = object({
    cpu        = string
    memory     = string
    nic_parent = string
  })
  description = "System requirement Definition for node to spawn"
}
