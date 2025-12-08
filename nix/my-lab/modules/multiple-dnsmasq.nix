{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.types)
    submodule
    attrsOf
    listOf
    str
    package
    ;
  inherit (lib)
    generators
    mapAttrs
    mapAttrs'
    nameValuePair
    ;

  cfg = config.services.dnsmasq;
  dnsmasq = cfg.package;
  stateDir = "/var/lib/dnsmasq";

  # True values are just put as `name` instead of `name=true`, and false values
  # are turned to comments (false values are expected to be overrides e.g.
  # lib.mkForce)
  formatKeyValue =
    name: value:
    if value == true then
      name
    else if value == false then
      "# setting `${name}` explicitly set to false"
    else
      generators.mkKeyValueDefault { } "=" name value;

  settingsFormat = pkgs.formats.keyValue {
    mkKeyValue = formatKeyValue;
    listsAsDuplicateKeys = true;
  };

  dnsmasqConfs = mapAttrs (
    name: settings:
    settingsFormat.generate name (
      settings
      // {
        # Common multiple dnsmasq settings
        bind-interfaces = true;
        except-interface = [ "lo" ];
      }
    )
  ) cfg.multipleSessions;
in
{
  ###### interface

  options = {

    services.dnsmasq = {
      multipleSessions = lib.mkOption {
        type =
          let
            settings = submodule {
              freeformType = settingsFormat.type;

              options.server = lib.mkOption {
                type = listOf str;
                default = [ ];
                example = [
                  "8.8.8.8"
                  "8.8.4.4"
                ];
                description = ''
                  The DNS servers which dnsmasq should query.
                '';
              };

            };
          in
          attrsOf settings;
        default = { };
        description = ''
          Configuration of dnsmasq. Lists get added one value per line (empty
          lists and false values don't get added, though false values get
          turned to comments). Gets merged with

              eth1 = {
                inhterface = "eth1";
                dhcp-leasefile = "dnsmasq/dnsmasq@<name>.leases";
                conf-file = optional cfg.resolveLocalQueries "/etc/dnsmasq@<name>-conf.conf";
                resolv-file = optional cfg.resolveLocalQueries "/etc/dnsmasq@<name>-resolv.conf";
              }
        '';
        example = lib.literalExpression ''
          eth1 = {
            inhterface = "eth1";
            domain-needed = true;
            dhcp-range = [ "192.168.0.2,192.168.0.254" ];
          }
        '';
      };

      configFiles = lib.mkOption {
        type = attrsOf package;
        readOnly = true;
        description = ''
          Attrset of path to the configuration files of dnsmasq.
        '';
      };

    };

  };

  ###### implementation

  config = lib.mkIf cfg.enable {

    services.dnsmasq = {
      configFiles = dnsmasqConfs;
    };

    systemd.services = {
      dnsmasq.enable = lib.mkForce false; # avoid conflict
    }
    // (mapAttrs' (
      name: configFile:
      nameValuePair "dnsmasq@${name}" {
        description = "Dnsmasq Daemon for ${name}";
        after = [
          "network.target"
          "systemd-resolved.service"
        ];
        wantedBy = [ "multi-user.target" ];
        path = [ dnsmasq ];
        preStart = ''
          mkdir -m 755 -p ${stateDir}
          mkdir -m 755 -p /var/run/dnsmasq
          touch ${stateDir}/dnsmasq@${name}.leases
          chown -R dnsmasq ${stateDir}
          ${lib.optionalString cfg.resolveLocalQueries "touch /etc/dnsmasq@${name}-{conf,resolv}.conf"}
          dnsmasq --test -C ${configFile} -x /var/run/dnsmasq/dnsmasq@${name}.pid
        '';
        serviceConfig = {
          # Type = "dbus";
          # BusName = "uk.org.thekelleys.dnsmasq";
          Type = "simple";
          ExecStart = "${dnsmasq}/bin/dnsmasq -k --user=dnsmasq -C ${configFile} -x /var/run/dnsmasq/dnsmasq@${name}.pid";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          PrivateTmp = lib.mkDefault true;
          ProtectSystem = lib.mkDefault true;
          ProtectHome = lib.mkDefault true;
          Restart = if cfg.alwaysKeepRunning then "always" else "on-failure";
        };
        restartTriggers = [ config.environment.etc.hosts.source ];
      }
    ) cfg.configFiles);
  };
}
