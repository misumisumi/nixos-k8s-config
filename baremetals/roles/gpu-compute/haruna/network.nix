{
  config,
  static,
  group,
  hostname,
  hostSecretPath,
  ...
}:
let
  inherit (static.${group}.${hostname}) networks;
in
{
  sops = {
    defaultSopsFile = hostSecretPath + "/secrets.yaml";
    secrets = {
      "wireguard/privatekey" = { };
      "wireguard/peers/oci/psk" = { };
    };
  };

  boot.kernelModules = [ "wireguard" ];
  apt.packages = [ "wireguard-tools" ];

  # Host-delegated NetworkManager: only /etc/NetworkManager/NetworkManager.conf is managed,
  # systemd units remain host's /lib/systemd/system (no /etc shadow). Enable when needed:
  networking.networkmanager.enable = false;
  # networking.networkmanager.settings.main.dhcp = "internal";
  # networking.networkmanager.ensureProfiles.profiles."haruna-wired" = {
  #   connection.id = "haruna-wired";
  #   connection.type = "ethernet";
  #   ipv4.method = "auto";
  # };

  # Host-delegated nftables: only /etc/nftables.conf via environment.etc,
  # no systemd.services.nftables shadowing host's nftables.service
  # (haruna/network.nix sets networking.nftables.enable = true with host ruleset;
  #  keep it host-managed, disable here only if you want to rely on ufw instead)
  # networking.nftables.ruleset = ''
  #   table inet filter {
  #     chain input { type filter hook input priority 0; iifname lo accept; ct state {established, related} accept; tcp dport 22 accept; counter drop }
  #     chain output { type filter hook output priority 0; accept }
  #     chain forward { type filter hook forward priority 0; accept }
  #   }
  # '';
  networking = {
    wg-quick = {
      interfaces = {
        wg0 = {
          mtu = 1280;
          address = [
            "10.250.0.55/24"
          ];
          peers = [
            {
              allowedIPs = [
                "10.250.0.0/24"
              ];
              endpoint = "wg.oci.misumi-sumi.com:443";
              publicKey = "BR2XCDtghHRZYqGryTPbal+Ms7gYlgzN+b+AAlWGIms=";
              presharedKeyFile = config.sops.secrets."wireguard/peers/oci/psk".path;
              persistentKeepalive = 11;
            }
          ];
          privateKeyFile = config.sops.secrets."wireguard/privatekey".path;
        };
      };
    };
  };
}
