variable "etcd_instances" {
  type        = set(string)
  description = "Name for etcd hosts to spawn"
}
variable "etcd_RD" {
  type        = map(string)
  description = "Requirement Definition for etcd hosts to spawn"
  default = {
    "cpu"    = "2"
    "memory" = "1GB"
  }
}

variable "control_plane_instances" {
  type        = set(string)
  description = "Name for control plane hosts to spawn"
}
variable "control_plane_RD" {
  type        = map(string)
  description = "Requirement Definition for control plane hosts to spawn"
  default = {
    "cpu"    = "2"
    "memory" = "1GB"
  }
}

variable "worker_instances" {
  type        = set(string)
  description = "Name for worker hosts to spawn"
}
variable "worker_RD" {
  type        = map(string)
  description = "Requirement Definition for worker hosts to spawn"
  default = {
    "cpu"    = "2"
    "memory" = "1GB"
  }
}

variable "load_balancer_instances" {
  type        = set(string)
  description = "Name for control plane load balancer hosts to spawn"
}
variable "load_balancer_RD" {
  type        = map(string)
  description = "Requirement Definition for load balancer hosts to spawn"
  default = {
    "cpu"    = "2"
    "memory" = "1GB"
  }
}