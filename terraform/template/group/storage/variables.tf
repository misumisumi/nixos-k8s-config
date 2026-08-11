variable "remote_hosts" {
  type = list(
    object({
      name    = optional(string, null)
      address = optional(string, null)
    })
  )
  default = []
}

variable "compornents" {
  type = list(
    object(
      {
        remote  = optional(string, "local")
        project = optional(string, "default")
        pools = list(object({
          name   = string
          driver = optional(string, "btrfs")
          config = map(any)
        }))
        volumes = list(object({
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
