variable "etcd_instances" {
  type        = set(map(string))
  description = "Name and some config for etcd hosts to spawn"
  default = [{
    "name"       = "etcd1"
    "target"     = null
    "ip_address" = null
  }]
}
variable "etcd_RD" {
  type        = map(string)
  description = "Requirement Definition for etcd hosts to spawn"
  default = {
    "cpu"        = "2"
    "memory"     = "1GiB"
    "nic_parent" = "br0"
  }
}

variable "control_plane_instances" {
  type        = set(map(string))
  description = "Name and some config for control plane hosts to spawn"
  default = [{
    "name"       = "control_plane1"
    "target"     = null
    "ip_address" = null
  }]
}
variable "control_plane_RD" {
  type        = map(string)
  description = "Requirement Definition for control plane hosts to spawn"
  default = {
    "cpu"        = "2"
    "memory"     = "1GiB"
    "nic_parent" = "br0"
  }
}

variable "worker_instances" {
  type        = set(map(string))
  description = "Name and some config for worker hosts to spawn"
  default = [{
    "name"       = "worker1"
    "target"     = null
    "ip_address" = null
  }]
}
variable "worker_RD" {
  type        = map(string)
  description = "Requirement Definition for worker hosts to spawn"
  default = {
    "cpu"        = "2"
    "memory"     = "1GiB"
    "nic_parent" = "br0"
  }
}

variable "load_balancer_instances" {
  type        = set(map(string))
  description = "Name and some config for load balancer hosts to spawn"
  default = [{
    "name"       = "load_balancer1"
    "target"     = null
    "ip_address" = null
  }]
}
variable "load_balancer_RD" {
  type        = map(string)
  description = "Requirement Definition for load balancer hosts to spawn"
  default = {
    "cpu"        = "2"
    "memory"     = "1GiB"
    "nic_parent" = "br0"
  }
}