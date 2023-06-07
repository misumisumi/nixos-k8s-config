variable "etcd_instances" {
  type = set(
    object({
      name       = string
      target     = optional(string, null)
      type       = optional(string, "container")
      ip_address = optional(string, null)
      devices    = optional(set(any), [])
    })
  )
  description = "Name and some config for etcd hosts to spawn"
}

variable "etcd_RD" {
  type = object({
    cpu        = optional(string, "2")
    memory     = optional(string, "1GiB")
    nic_parent = optional(string, "k8sbr0")
  })
  description = "Requirement Definition for etcd hosts to spawn"
}

variable "control_plane_instances" {
  type = set(
    object({
      name       = string
      target     = optional(string, null)
      type       = optional(string, "container")
      ip_address = optional(string, null)
      devices    = optional(set(any), [])
    })
  )
  description = "Name and some config for control plane hosts to spawn"
}
variable "control_plane_RD" {
  type = object({
    cpu        = optional(string, "2")
    memory     = optional(string, "1GiB")
    nic_parent = optional(string, "k8sbr0")
  })
  description = "Requirement Definition for control plane hosts to spawn"
}

variable "worker_instances" {
  type = set(
    object({
      name       = string
      target     = optional(string, null)
      type       = optional(string, "container")
      ip_address = optional(string, null)
      devices    = optional(set(any), [])
    })
  )
  description = "Name and some config for worker hosts to spawn"
}
variable "worker_RD" {
  type = object({
    cpu        = optional(string, "2")
    memory     = optional(string, "1GiB")
    nic_parent = optional(string, "k8sbr0")
  })
  description = "Requirement Definition for worker hosts to spawn"
}

variable "load_balancer_instances" {
  type = set(
    object({
      name       = string
      target     = optional(string, null)
      type       = optional(string, "container")
      ip_address = optional(string, null)
      devices    = optional(set(any), [])
    })
  )
  description = "Name and some config for load balancer hosts to spawn"
}
variable "load_balancer_RD" {
  type = object({
    cpu        = optional(string, "2")
    memory     = optional(string, "1GiB")
    nic_parent = optional(string, "k8sbr0")
  })
  description = "Requirement Definition for load balancer hosts to spawn"
}

variable "optional_instances" {
  type = set(
    object({
      instance_name = string
      nodes = set(
        object({
          name       = string
          target     = optional(string, null)
          type       = optional(string, "container")
          ip_address = optional(string, null)
          devices    = optional(set(any), [])
        })
      )
      instance_RD = object({
        cpu        = optional(string, "2")
        memory     = optional(string, "1GiB")
        nic_parent = optional(string, "k8sbr0")
      })
    })
  )
  description = "Name and some config for optional hosts to spawn"
}

variable "pools" {
  type        = set(any)
  description = "Strage pool propaties"
  default     = []
}
