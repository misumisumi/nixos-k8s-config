variable "install_user" {
  type = string
}
variable "install_ssh_key" {
  type = string
}
variable "target_host" {
  type = string
}
variable "instance_id" {
  type = string
}
variable "phases" {
  type    = set(string)
  default = ["kexec", "disko", "install", "reboot"]
}
