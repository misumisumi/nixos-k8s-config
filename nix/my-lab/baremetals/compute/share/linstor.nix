{
  lib,
  config,
  static,
  group,
  ...
}:
let
  inherit (lib) mapAttrsToList concatStringsSep;

  inherit (config) linkage;
  inherit (static.${group}) virtualIPs;
  VIPConfig = linkage.highAvailable.virtualIP;
  controllers = [
    "${VIPConfig.address}"
    "${virtualIPs.linstor.address}"
  ]
  ++ (mapAttrsToList (_: node: "${node.address}") linkage.nodes);
in
{
  services.linstor = {
    satellite.enable = true;
    controller.enable = true;
    gateway = {
      enable = true;
      settings = {
        linstor = {
          inherit controllers;
        };
      };
    };
    client = {
      enable = true;
      settings = {
        global = {
          controllers = concatStringsSep "," controllers;
          timeout = "10";
        };
      };
    };
    highAvailable = {
      enable = true;
      settings = {
        promoter = [
          {
            resources = {
              linstor_db = {
                start = [
                  "var-lib-linstor.mount"
                  # "ocf:heartbeat:DummyIF linstor_vip ifname=${VIPConfig.ifname} ip=${VIPConfig.address} cidr_netmask=${VIPConfig.cidr}"
                  "ocf:heartbeat:IPaddr2 linstor_vip ip=${VIPConfig.address} cidr_netmask=${VIPConfig.cidr}"
                  "ocf:heartbeat:IPaddr2 linstor_vip_bgp ip=${virtualIPs.linstor.address} cidr_netmask=${virtualIPs.linstor.cidr}"
                  "linstor-controller.service"
                ];
              };
            };
          }
        ];
      };
    };
  };
}
