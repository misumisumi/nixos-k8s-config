pool     = "LVM4QEMU"
cpu_mode = "host-passthrough"
nodes = [
  {
    name = "node1"
    disks = [
      {
        name = "diskA"
      },
      {
        name = "diskB"
      },
      {
        name = "diskC"
      }
    ]
  },
  {
    name = "node2"
    disks = [
      {
        name = "diskD"
      },
      {
        name = "diskE"
      },
      {
        name = "diskF"
      }
    ]
  },
  {
    name = "node3"
    disks = [
      {
        name = "diskG"
      },
      {
        name = "diskH"
      }
    ]
  }
]

