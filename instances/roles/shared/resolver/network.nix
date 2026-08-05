{ ... }: {
  systemd.network.networks."10-enp5s0" = {
    name = "enp5s0";
    networkConfig.Description = "Management network";
    routes = [
      { Destination = "0.0.0.0/0"; Gateway = "172.16.1.253"; }
    ];
  };
}
