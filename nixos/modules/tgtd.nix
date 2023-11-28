{ lib
, pkgs
, config
, ...
}: with lib;
let
  cfg = config.services.tgtd;
  targets = types.submodule {
    options = {
      backingStores = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = "Defines a logical unit (LUN) exported by the target.";
      };
      directStores = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = "Defines a direct mapped logical unit (LUN) with the same properties as the physical devices.";
      };
      useIser = mkEnableOption "Use 'iser' driver";
      initiatorAddresses = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = "Allows connections only from the specified IP addresses.";
      };
      initiatorNames = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = "Allows connections only from the specified initiator names.";
      };
      incomingusers = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = "Define iscsi incoming authentication setting. ";
      };
      outgoingusers = mkOption {
        type = types.listOf (types.str);
        default = [ ];
        description = "Define iscsi outgoing authentication setting.";
      };
    };
  };
  mkConfig = targets: mapAttrsToList
    (name: values: ''
      <target ${name}>
      ${concatMapStrings (x: "\tbacking-store ${x}\n") values.backingStores}
      ${concatMapStrings (x: "\tdirect-store ${x}\n") values.directStores}

      ${optionalString values.useIser "\tdriver iser"}

      ${concatMapStrings (x: "\tinitiator-address  ${x}\n") values.initiatorAddresses}
      ${concatMapStrings (x: "\tinitiator-name  ${x}\n") values.initiatorNames}

      ${concatMapStrings (x: "\tincominguser  ${x}\n") values.incomingusers}
      ${concatMapStrings (x: "\toutgoinguser  ${x}\n") values.outgoingusers}
      </target>
    '')
    targets;
in
{
  options.services.tgtd = {
    enable = mkEnableOption "Enable tgtd service";
    nop_interval = mkOption {
      type = types.number;
      default = 0;
      description = "Default interval for sending NOP-OUT to probe for connected initiators.";
    };
    nop_count = mkOption {
      type = types.number;
      default = 0;
      description = "Default value for after how many failed probes TGTD will consider the initiator dead and tear down the session";
    };
    targets = mkOption {
      type = types.attrOf (targets);
      default = { };
      description = "iSCSI targets with config";
    };
  };
  config = mkIf cfg.enable {
    environment.etc."tgt/targets.conf" = {
      text = concatStringsSep (mkConfig cfg.targets);
    };
    systemd.services.tgtd = {
      description = "Start iSCSI target daemon";
      wantedBy = [ "basic.target" ];
      serviceConfig =
        let
          tgtd = "${pkgs.tgt}/bin/tgtd";
          tgtadm = "${pkgs.tgt}/bin/tgtadm";
          tgt-admin = "${pkgs.tgt}/bin/tgt-admin";
          sleep = "${pkgs.coreutils}/bin/sleep";
          tgtd-config = "/etc/tgt/targets.conf";
        in
        {
          ExecStart = "${tgtd} --iscsi nop_interval=${cfg.nop_interval} --iscsi nop_count=${cfg.nop_count}";
          ExecStartPost = "${sleep} 5 ; ${tgtadm} --op update --mode sys --name State -v offline ; ${tgtadm} --op update --mode sys --name State -v ready; ${tgt-admin} -e -c ${tgtd-config}";
          ExecReload = "${tgt-admin} --update ALL -f -c ${tgtd-config}";
          ExecStop = "${sleep} 10 ; ${tgtadm} --op update --mode sys --name State -v offline ; ${tgt-admin} --offline ALL ; ${tgt-admin} --update ALL -c /dev/null -f ; ${tgtadm} --op delete --mode system";
          KillMode = "process";
          Restart = "on-success";
        };
    };
  };
}