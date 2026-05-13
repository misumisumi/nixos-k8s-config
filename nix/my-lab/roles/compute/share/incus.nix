{
  lib,
  pkgs,
  user,
  config,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (static.${group}.${hostname}) routerId;
  inherit (static.${group}) virtualIPs;
in
{
  environment.systemPackages = with pkgs; [
    sshfs
    virtiofsd
  ];
  users.groups = {
    incus-admin.members = [
      "root"
      "${user}"
    ];
    kvm.members = [
      "root"
      "${user}"
    ];
  };

  virtualisation = {
    vswitch.enable = true;
    incus = {
      enable = true;
      ui.enable = true;
      startTimeout = 300;
      package = pkgs.incus;
      # bucketSupport = false;
      preseed = {
        config = {
          "core.https_address" = ":8443";
          "core.trust_ca_certificates" = "true";
          "cluster.https_address" = "${routerId}:8443";
          "storage.linstor.controller_connection" = "http://${virtualIPs.linstor.address}:3370";
        };
      };
    };
  };

  services.rpcbind.enable = true; # For NFS
  #NOTE: /var/lib/incusはLINSTOR-GATEWAYが提供するNFSサーバーからマウントする
  # そのため、incusのサービスは/var/lib/incusがマウントされる前に起動してはいけない
  # また、wantedBy=multi-user.targetにするとマウントされるまでttyが起動せず、sshでログインできなくなる
  # そのため、multi-user.targetの後にincus.{service,socket}が起動するようにする必要がある
  systemd = {
    services = {
      link-server-certs-to-incus = {
        description = "Link certificates for incus";
        after = [ "multi-user.target" ];
        script = ''
          mkdir -p /var/lib/incus
          cp /var/lib/certs/server/* /var/lib/incus/
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        unitConfig = {
          RequiresMountsFor = "/var/lib/incus";
        };
      };
      incus = {
        wantedBy = mkForce [ ];
        requires = [
          "link-server-certs-to-incus.service"
        ];
        after = [
          "link-server-certs-to-incus.service"
          "multi-user.target"
        ];
        unitConfig = {
          RequiresMountsFor = "/var/lib/incus";
        };
      };
    };
    sockets = {
      incus.after = [ "multi-user.target" ];
      incus-user.after = [ "multi-user.target" ];
    };
    mounts = [
      {
        type = "nfs";
        after = [ "multi-user.target" ];
        mountConfig = {
          Options = "noatime,timeo=100,retrans=10";
          DirectoryMode = "711";
        };
        what = "${virtualIPs.nfs.address}:/srv/gateway-exports/${config.linkage.gateway.nfs.name}/${hostname}/incus";
        where = "/var/lib/incus";
      }
    ];
  };
  # systemd.services.incus.serviceConfig = {
  #   ExecStart = lib.mkForce "${config.virtualisation.incus.package}/bin/incusd --group incus-admin --verbose";
  #   ExecStartPost = lib.mkForce "${config.virtualisation.incus.package}/bin/incusd waitready --timeout=${config.virtualisation.incus.startTimeout}";
  # };
}
