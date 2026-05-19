{
  hardware.infiniband = {
    enable = true;
    guids = [ ];
  };
  environment.etc."rdma/opensm.conf".text = ''
    sm_priority 5
    sminfo_polling_timeout 5000 # msec
  '';
}
