variable "remote_hosts" {
  type = set(
    object({
      name    = optional(string, null)
      address = optional(string, null)
    })
  )
  default = []
}

variable "pools" {
  type = map(
    object(
      {
        remote = optional(string, null)
        project = optional(string, null)
        driver = optional(string, "btrfs")
        config = map(any)
      }
    )
  )
  description = "Strage pool propaties"
}
