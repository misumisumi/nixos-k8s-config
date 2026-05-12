{
  pkgs,
  user,
  config,
  static,
  group,
  hostname,
  ...
}:
let
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
  systemd = {
    services = {
      check-var-lib-incus = {
        description = "Check if NFS server is reachable";
        before = [ "var-lib-incus.mount" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        requiredBy = [ "var-lib-incus.mount" ];
        script = ''
          i=0
          RETRIES=100
          SLEEP_TIME=10
          STEPS=4
          until ${pkgs.iputils}/bin/ping -c 1 -W 1 "${virtualIPs.nfs.address}" >/dev/null 2>&1; do
              i=$((i+1))
              if [ "$i" -ge "$RETRIES" ]; then
                  echo "failed to reach after $RETRIES tries"
                  exit 1
              fi
              if [[ "$i" -le "$STEPS" ]]; then
                SLEEP_TIME=$((SLEEP_TIME*2))
              fi
              echo "[$i/$RETRIES]: ping failed, retrying in $SLEEP_TIME seconds..."
              sleep $SLEEP_TIME
          done
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
      link-server-certs-for-incus = {
        description = "Link certificates for incus";
        requires = [
          "check-var-lib-incus.service"
          "var-lib-incus.mount"
        ];
        after = [
          "check-var-lib-incus.service"
          "var-lib-incus.mount"
        ];
        script = ''
          cp /var/lib/certs/server/* /var/lib/incus/
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
      incus = {
        requires = [ "link-server-certs-for-incus.service" ];
        bindsTo = [ "var-lib-incus.mount" ];
        after = [
          "link-server-certs-for-incus.service"
          "var-lib-incus.mount"
        ];
      };
    };
    mounts = [
      {
        type = "nfs";
        mountConfig = {
          Options = "noatime";
        };
        requiredBy = [ "incus.service" ];
        before = [ "incus.service" ];
        what = "${virtualIPs.nfs.address}:/srv/gateway-exports/${config.linkage.gateway.nfs.name}/${hostname}/incus";
        where = "/var/lib/incus";
      }
    ];
    automounts = [
      {
        wantedBy = [ "multi-user.target" ];
        where = "/var/lib/incus";
        automountConfig = {
          DirectoryMode = "711";
        };
      }
    ];
  };
  # systemd.services.incus.serviceConfig = {
  #   ExecStart = lib.mkForce "${config.virtualisation.incus.package}/bin/incusd --group incus-admin --verbose";
  #   ExecStartPost = lib.mkForce "${config.virtualisation.incus.package}/bin/incusd waitready --timeout=${config.virtualisation.incus.startTimeout}";
  # };
}
