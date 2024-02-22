variable "remote_hosts" {
  type = set(
    object({
      name    = optional(string, null)
      address = optional(string, null)
    })
  )
  default = []
}

variable "networks" {
  type = map(object({
    project = optional(string, null)
    remote = optional(string, null)
    config = map(any)
  }))
  description = "Network configs"
}
