{ static, ... }:
let
  networks = static.microvm.borderRouter.networks;
in
{
  microvm.interfaces = [
    {
      type = "macvtap";
      id = "vm_router2wan";
      mac = "20:10:00:00:00:01";
      macvtap = {
        link = networks.wan.parent;
        mode = "bridge";
      };
    }
  ];
}
