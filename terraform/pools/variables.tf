variable "remote_hosts" {
  type = set(
    object({
      name    = optional(string, null)
      address = optional(string, null)
    })
  )
  default = []
}

variable "compornents" {
  type = set(
    object(
      {
        remote  = optional(string, "local")
        project = optional(string, null)
        pools = set(object({
          name   = string
          driver = optional(string, "btrfs")
          config = map(any)
        }))
        volumes = set(object({
          name         = string
          pool         = string
          content_type = optional(string, null)
          config       = optional(map(string), {})
        }))
      }
    )
  )
  description = "Strage pool propaties"
}
