{
  pkgs,
  lib,
  static,
  isDev,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    flatten
    imap1
    importTOML
    mapAttrsToList
    ;
  k8sStatic = if isDev then importTOML ../../static_dev.toml else importTOML ../../static.toml;

  homeZone =
    let
      nodeNameIPPairs = flatten (
        mapAttrsToList (
          n: v: imap1 (i: ip: "${n}${toString i} IN A ${ip}") (v.nodeIPs or [ ])
        ) k8sStatic.nodes
      );
    in
    pkgs.writeText "home.zone" ''
      $ORIGIN home.
      @ IN SOA ns.home. admin.home. (
          2026061401 ; Serial
          3600       ; Refresh
          1800       ; Retry
          604800     ; Expire
          86400      ; Minimum TTL
      )
      @ IN NS ns.home.
      ns IN A ${static.shared.dns.manageIP}

      ; nodes for k8s cluster
      ${concatStringsSep "\n" nodeNameIPPairs}
    '';
in
{
  environment.systemPackages = with pkgs; [ pdns ];
  networking = {
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
    nftables.enable = true;
    firewall = {
      allowedTCPPorts = [
        53 # DNS
        8081 # PowerDNS API
      ];
      allowedUDPPorts = [
        53 # DNS
      ];
    };
  };
  services = {
    resolved.enable = false;
    powerdns = {
      enable = true;
      # allow-dnsupdate-from=127.0.0.0/8,::1,172.16.0.0/16

      extraConfig = ''
        local-address=127.0.0.1, ::1, ${static.shared.dns.manageIP}
        local-port=53

        # backend
        launch=gsqlite3
        gsqlite3-database=/var/lib/powerdns/pdns.sqlite3

        # Enable api
        api=yes
        api-key=HogeHoge
        webserver=yes
        webserver-address=0.0.0.0
        webserver-port=8081
        webserver-allow-from=172.16.0.0/16
        webserver-password="hogehoge"
      '';
    };
  };
  systemd.services = {
    pdns-prepare-db = {
      requiredBy = [ "pdns.service" ];
      before = [ "pdns.service" ];
      unitConfig.ConditionPathExists = "!/var/lib/powerdns/pdns.sqlite3";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /var/lib/powerdns
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/powerdns/pdns.sqlite3 < ${pkgs.pdns}/share/doc/pdns/schema.sqlite3.sql
        chown -R pdns:pdns /var/lib/powerdns
      '';
    };
    setup-zone = {
      description = "Setup DNS zone for powerdns";
      wantedBy = [
        "pdns.service"
        "multi-user.target"
      ];
      after = [ "pdns.service" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        ${pkgs.pdns}/bin/pdnsutil zone load home ${homeZone}

        # misumi-sumi.com は存在しない場合のみ作成（external-dns が動的レコードを管理）
        if ! ${pkgs.pdns}/bin/pdnsutil list-zone misumi-sumi.com > /dev/null 2>&1; then
          ${pkgs.pdns}/bin/pdnsutil create-zone misumi-sumi.com ns.home.
        fi
      '';
    };
  };

  # fileSystems."/var/lib/powerdns" = {
  #   device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_pdns";
  #   fsType = "ext4";
  #   autoFormat = true;
  # };
}
