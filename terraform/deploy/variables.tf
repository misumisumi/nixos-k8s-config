variable "nodes" {
  type = set(
    object({
      name = string
      ipv4 = string
    })
  )
  description = "target nodes"
}
