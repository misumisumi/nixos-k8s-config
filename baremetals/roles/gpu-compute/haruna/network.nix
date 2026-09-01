{
  config,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (static.${group}.${hostname}) networks;
in
{
  systemd.network.networks."10-manage" = {
    name = networks.manage.IF;
    networkConfig = {
      Description = "Management network";
    };
    address = [ networks.manage.address ];
  };

  networking = {
    nftables.enable = true;
    firewall = {
      enable = true;
    };
    wg-quick = {
      interfaces = {
        wg0 = {
          autostart = false;
          mtu = 1280;
          address = [
            "10.250.0.50/24"
          ];
          dns = [ "10.250.0.1" ];
          peers = [
            {
              allowedIPs = [
                "10.250.0.0/24"
                "192.168.1.0/24"
              ];
              endpoint = "oci.misumi-sumi.com:443";
              publicKey = "BR2XCDtghHRZYqGryTPbal+Ms7gYlgzN+b+AAlWGIms=";
              presharedKeyFile = config.sops.secrets.wg_peer_oci_presharedKey.path;
              persistentKeepalive = 25;
            }
          ];
          privateKeyFile = config.sops.secrets.wg_privateKey.path;
        };
      };
    };
  };
}
