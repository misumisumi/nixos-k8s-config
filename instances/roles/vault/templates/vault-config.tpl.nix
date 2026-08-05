{
  lib,
  pkgs,
  static,
  ...
}:
let
  inherit (lib) concatStringsSep;
  retryJoinLines = concatStringsSep "\n" (
    map (ip: ''
      retry_join {
        leader_api_addr = "https://${ip}:8200"
      }
    '') static.vault.vault.nodeIPs
  );
in
{
  virtualisation.lxc.templates."vaultConfig" = {
    enable = true;
    target = "/etc/vault/vault.hcl";
    template = pkgs.writeText "vault.hcl.tpl" ''
      {% set num = container.name | cut:"vault" | integer %}
      ui = true
      disable_mlock = true

      api_addr = "https://{{ devices.eth0['ipv4.address'] }}:8200"
      cluster_addr = "https://{{ devices.eth0['ipv4.address'] }}:8201"

      storage "raft" {
        path = "/var/lib/vault"
        node_id = "vault{{ num }}"
      ${retryJoinLines}
      }

      listener "tcp" {
        address       = "0.0.0.0:8200"
        tls_cert_file = "/etc/vault/tls/server.pem"
        tls_key_file  = "/etc/vault/tls/server-key.pem"
      }
    '';
    when = [ "create" ];
  };
}
