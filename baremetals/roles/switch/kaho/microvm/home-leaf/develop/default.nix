{ static, ... }:
let
  networks = static.microvm.homeLeaf.networks;
in
{
  microvm.interfaces = [
    {
      type = "macvtap";
      id = "vm_leaf2hm10Gd0";
      mac = "20:20:00:00:00:ba";
      macvtap = {
        link = networks.apTrunk.parent;
        mode = "passthru";
      };
    }
    {
      type = "macvtap";
      id = "vm_leaf2hm10Gd1";
      mac = "20:20:00:00:00:bb";
      macvtap = {
        link = networks.intra10G_2.parent;
        mode = "passthru";
      };
    }
    {
      type = "macvtap";
      id = "vm_leaf2hm40g";
      mac = "20:20:00:00:00:bc";
      macvtap = {
        link = networks.intra40G_4.parent;
        mode = "passthru";
      };
    }
  ];
}
