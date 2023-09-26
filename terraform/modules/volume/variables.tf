variable "volumes" {
  type = set(
    object(
      {
        name         = optional(string, null)
        remote       = optional(string, null)
        pool         = optional(string, null)
        content_type = optional(string, null)
      }
    )
  )
  description = "Storage volume propaties for ceph"
}
