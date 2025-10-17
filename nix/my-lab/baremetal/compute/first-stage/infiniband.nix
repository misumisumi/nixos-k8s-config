{ lib, ... }:
{
  hardware.infiniband.enable = true;
  environment.etc."rdma/opensm.conf".text = lib.mkDefault ''
    sm_priority 5
    sminfo_polling_timeout 5000 # msec
  '';
}
