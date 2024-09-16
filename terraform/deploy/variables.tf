variable "nodes" {
  type = set(
    object({
      name = string
      ipv4 = string
    })
  )
  description = "target nodes"
}

variable "ignore_systemd_errors" {
  type        = bool
  description = "Ignore systemd errors happening during deploy"
  default     = false
}

variable "switch_cmd" {
  type        = string
  description = "One required argument, which specifies the desired operation."
  default     = "switch"
  validation {
    condition     = contains(["switch", "boot", "test"], var.switch_cmd)
    error_message = "The argument must be one of 'switch', 'boot', or 'test'."
  }
}

