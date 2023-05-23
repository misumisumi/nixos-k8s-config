variable "memory" {
  type        = string
  description = "Amount of megabytes of RAM to give to each machine"
}

variable "cpu" {
  type        = number
  description = "Number of cpu to give to each machine"
}

variable "name" {
  type        = string
  description = "Base name for the machine and boot volume"
}

variable "num_replicas" {
  type        = number
  description = "Amount of machines to spawn"
}
