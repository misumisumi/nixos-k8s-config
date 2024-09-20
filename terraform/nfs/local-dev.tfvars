compornents = [
  {
    remote = "local"
    profiles = [
      {
        tag       = "nfs"
        root_pool = "instances"
      }
    ]
    instances = [
      {
        name         = "nfs1"
        machine_type = "virtual-machine"
        image        = "images:almalinux/9/cloud"
        network_config = {
          parent         = "k8sbr0"
          hwaddr         = "56:f1:ff:2a:76:c5"
          "ipv4.address" = "10.150.10.71"
        }
        config = {
          "cloud-init.user-data" = <<-EOT
            #cloud-config
            timezone: Asia/Tokyo
            users:
              - default

            yum_repos:
              zfs:
                baseurl: http://download.zfsonlinux.org/epel/$releasever/$basearch/
                metadata_expire: 7d
                enabled: 1
                gpgcheck: 1
                gpgkey: https://raw.githubusercontent.com/zfsonlinux/zfsonlinux.github.com/master/zfs-release/RPM-GPG-KEY-openzfs-key2
              epel-release:
                baseurl: http://download.fedoraproject.org/pub/epel/9/Everything/$basearch
                enabled: 1
                gpgcheck: 1
                countme: 1
                gpgkey: http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9

            package_update: true
            package_reboot_if_required: true
            packages:
              - drbd9x-utils
              - firewalld
              - kmod-drbd9x
              - less
              - neofetch
              - tar
              - wget
              - zfs

            rumcmd:
              - [ reboot ]
          EOT
        }
        limits = {
          cpu    = "2"
          memory = "4GiB"
        }
        devices = [
          {
            name = "agent"
            type = "disk"
            properties = {
              source = "agent:config"
            }
          },
          {
            name = "nfs"
            type = "disk"
            properties = {
              pool   = "nfs"
              source = "nfs1"
            }
          }
        ]
      },
      {
        name         = "nfs2"
        machine_type = "virtual-machine"
        image        = "images:almalinux/9/cloud"
        network_config = {
          parent         = "k8sbr0"
          hwaddr         = "56:f1:ff:2a:76:c5"
          "ipv4.address" = "10.150.10.71"
        }
        config = {
          "cloud-init.user-data" = <<-EOT
            #cloud-config
            timezone: Asia/Tokyo
            users:
              - default

            yum_repos:
              zfs:
                baseurl: http://download.zfsonlinux.org/epel/$releasever/$basearch/
                metadata_expire: 7d
                enabled: 1
                gpgcheck: 1
                gpgkey: https://raw.githubusercontent.com/zfsonlinux/zfsonlinux.github.com/master/zfs-release/RPM-GPG-KEY-openzfs-key2
              epel-release:
                baseurl: http://download.fedoraproject.org/pub/epel/9/Everything/$basearch
                enabled: 1
                gpgcheck: 1
                countme: 1
                gpgkey: http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9

            package_update: true
            package_reboot_if_required: true
            packages:
              - drbd9x-utils
              - firewalld
              - kmod-drbd9x
              - less
              - neofetch
              - tar
              - wget
              - zfs

            rumcmd:
              - [ reboot ]
          EOT
        }
        limits = {
          cpu    = "2"
          memory = "4GiB"
        }
        devices = [
          {
            name = "agent"
            type = "disk"
            properties = {
              source = "agent:config"
            }
          },
          {
            name = "nfs"
            type = "disk"
            properties = {
              pool   = "nfs"
              source = "nfs2"
            }
          }
        ]
      },
    ]
  }
]

