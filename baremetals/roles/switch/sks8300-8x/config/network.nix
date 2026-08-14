{
  lib,
  writeText,
  static,
}:
let
  inherit (static.switch.sks8300-8x.bgp) routerId;
  inherit (static.switch.sks8300-8x.networks.manage) IF address;
  manageIP = lib.removeNetmask address;
  netmask = lib.getNetmask address;
in
writeText "network" ''
  config interface 'loopback'
      option device 'lo'
      option proto 'static'
      option ipaddr '127.0.0.1'
      option netmask '255.0.0.0'

  config interface 'bgp-loopback'
      option device 'lo'
      option proto 'static'
      option ipaddr '${routerId}'
      option netmask '255.255.255.255'

  config interface 'manage'
      option device '${IF}'
      option proto 'static'
      option ipaddr '${manageIP}'
      option netmask '${netmask}'

  config interface 'bgp1'
      option device 'eth1'
      option proto 'none'

  config interface 'bgp2'
      option device 'eth2'
      option proto 'none'

  config interface 'bgp3'
      option device 'eth3'
      option proto 'none'

  config interface 'bgp4'
      option device 'eth4'
      option proto 'none'

  config globals 'globals'
      option ula_prefix 'auto'

''
