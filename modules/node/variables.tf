variable "memory" {
  type        = string
  description = "Amount of megabytes of RAM to give to each machine"
}

variable "cpu" {
  type        = number
  description = "Number of cpu to give to each machine"
}

variable "nic_parent" {
  type        = string
  description = "Parent of network bridge (only set host bridge device)"
}

variable "name" {
  type        = string
  description = "Base name for the machine and boot volume"
}

variable "node_names" {
  type        = set(map(string))
  description = "Name to give to each nodes"
}