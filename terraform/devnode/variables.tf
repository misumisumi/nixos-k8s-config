# TODO: all variable move to nodes
variable "nodes" {
  type = set(
    object({
      name   = string
      distro = optional(string, "nixos")
      config = optional(object({
        cpu_mode     = optional(string, "host-model")
        root_size    = optional(number, 34359738368) # 32GiB
        storage_pool = optional(string, "default")
        firmware     = optional(string, "/run/libvirt/nix-ovmf/OVMF_CODE.fd")
        emulator     = optional(string, "/run/libvirt/nix-emulators/qemu-system-x86_64")
        vcpu         = optional(number, 4)
        memory       = optional(string, "4092")
      }))
      network = object({
        bridge      = optional(string, "br0")
        addresses   = optional(set(string), [])
        mac_address = optional(string)
      })
      disks = optional(set(
        object({
          name         = string
          storage_pool = optional(string, "default")
          size         = optional(number, 1073741824) # 1GiB
        }))
      )
    })
  )
  description = "libvirt components"
}
