variable "etcd_instances" {
  type        = number
  description = "Amount of etcd hosts to spawn"
}

variable "control_plane_instances" {
  type        = number
  description = "Amount of control plane hosts to spawn"
}

variable "worker_instances" {
  type        = number
  description = "Amount of worker hosts to spawn"
}

variable "load_balancer_instances" {
  type        = number
  description = "Amount of control plane load balancer hosts to spawn"
}