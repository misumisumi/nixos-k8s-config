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
  type = set(
    object({
      name         = optional(string, "devnet")
      ipv4_address = optional(string, "none")
      ipv6_address = optional(string, "none")
      nat          = optional(bool, true)
    })
  )
  description = "Network configs"
}