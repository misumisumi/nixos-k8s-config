variable "remote_hosts" {
  type = list(
    object({
      name    = optional(string, null)
      address = optional(string, null)
    })
  )
  default = []
}

variable "networks" {
  type = map(object({
    project = optional(string, "default")
    remote  = optional(string, null)
    peers   = optional(list(string), [])
    config  = map(any)
  }))
  description = "Network configs"
}
