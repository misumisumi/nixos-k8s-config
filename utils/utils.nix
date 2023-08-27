{
  # nodeIP = r: let
  #   interface = builtins.head r.values.network_interface;
  # in (builtins.head interface.addresses);
  nodeIP = r: r.values.ip_address;
}
