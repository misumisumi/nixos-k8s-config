variable "distro" {
  type        = string
  description = "The distribution to use"
  default     = "nixos"
}

variable "cpu_mode" {
  type        = string
  description = "The CPU mode to use"
  default     = "qemu64"
}

variable "pool" {
  type        = string
  description = "The storage pool to use"
  default     = "default"
}

variable "firmware" {
  type        = string
  description = "The firmware to use"
  default     = "/run/libvirt/nix-ovmf/OVMF_CODE.fd"
}

variable "emulator" {
  type        = string
  description = "The emulator to use"
  default     = "/run/libvirt/nix-emulators/qemu-system-x86_64"
}

variable "vcpu" {
  type        = number
  description = "The number of VCPUs to use"
  default     = 4
}

variable "memory" {
  type        = string
  description = "The amount of memory to use"
  default     = "4092"
}

variable "bridge" {
  type        = string
  description = "The bridge to use"
  default     = "br0"
}

variable "nodes" {
  type = set(
    object({
      name      = string
      root_size = optional(number, 34359738368) # 32GiB
      disks = optional(set(
        object({
          name = string
          size = optional(number, 1073741824) # 1GiB
        }))
      )
    })
  )
  description = "libvirt components"
}
