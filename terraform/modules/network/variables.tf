variable "name" {
  type        = string
  description = "Network name"
}
variable "ipv4_address" {
  type        = string
  description = "Network ipv4 address range"
}
variable "ipv6_address" {
  type        = string
  description = "Network ipv4 address range"
}
variable "nat" {
  type        = bool
  default     = true
  description = "Enable NAT on network"
}
