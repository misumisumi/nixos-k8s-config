variable "name" {
  type        = string
  description = "Base name for the machine and boot volume"
}

variable "nodes" {
  type        = set(map(string))
  description = "Name to give to each nodes"
}

variable "node_rd" {
  type        = map(string)
  description = "System requirement Definition for node to spawn"
  default = {
    "cpu"        = 2
    "memory"     = "1GiB"
    "nic_parent" = "lxdbr0"
  }
}