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
  type        = set(any)
  description = "Strage pool propaties"
  default     = []
}
