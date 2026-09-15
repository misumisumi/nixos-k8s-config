{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
with utils;
with systemdUtils.unitOptions;
with lib;
let
  cfg = config.systemd.user;

  inherit (systemdUtils.lib)
    generateUnits
    targetToUnit
    sliceToUnit
    socketToUnit
    timerToUnit
    pathToUnit
    ;

  upstreamUserUnits = [
    "app.slice"
    "background.slice"
    "basic.target"
    "bluetooth.target"
    "capsule@.target"
    "default.target"
    "exit.target"
    "graphical-session-pre.target"
    "graphical-session.target"
    "paths.target"
    "printer.target"
    "session.slice"
    "shutdown.target"
    "smartcard.target"
    "sockets.target"
    "sound.target"
    "systemd-exit.service"
    "timers.target"
    "xdg-desktop-autostart.target"
  ]
  ++ config.systemd.additionalUpstreamUserUnits;
in
{
  options = {
    systemd.user.extraConfig = mkOption {
      default = "";
      type = types.lines;
      example = "DefaultTimeoutStartSec=60";
      description = ''
        Extra config options for systemd user instances. See {manpage}`systemd-user.conf(5)` for
        available options.
      '';
    };

    systemd.user.units = mkOption {
      description = "Definition of systemd per-user units.";
      default = { };
      type = systemdUtils.types.units;
    };

    systemd.user.paths = mkOption {
      default = { };
      type = systemdUtils.types.paths;
      description = "Definition of systemd per-user path units.";
    };

    systemd.user.slices = mkOption {
      default = { };
      type = systemdUtils.types.slices;
      description = "Definition of systemd per-user slice units.";
    };

    systemd.user.sockets = mkOption {
      default = { };
      type = systemdUtils.types.sockets;
      description = "Definition of systemd per-user socket units.";
    };

    systemd.user.targets = mkOption {
      default = { };
      type = systemdUtils.types.targets;
      description = "Definition of systemd per-user target units.";
    };

    systemd.user.timers = mkOption {
      default = { };
      type = systemdUtils.types.timers;
      description = "Definition of systemd per-user timer units.";
    };

    systemd.additionalUpstreamUserUnits = mkOption {
      default = [ ];
      type = types.listOf types.str;
      example = [ ];
      description = ''
        Additional units shipped with systemd that should be enabled for per-user systemd instances.
      '';
      internal = true;
    };
  };

  config = {
    environment.etc = {
      "systemd/user".source = generateUnits {
        type = "user";
        inherit (cfg) units;
        upstreamUnits = upstreamUserUnits;
        upstreamWants = [ ];
      };

      "systemd/user.conf".text = ''
        [Manager]
        ${cfg.extraConfig}
      '';
    };

    systemd.user.units =
      mapAttrs' (n: v: nameValuePair "${n}.path" (pathToUnit v)) cfg.paths
      // mapAttrs' (n: v: nameValuePair "${n}.slice" (sliceToUnit v)) cfg.slices
      // mapAttrs' (n: v: nameValuePair "${n}.socket" (socketToUnit v)) cfg.sockets
      // mapAttrs' (n: v: nameValuePair "${n}.target" (targetToUnit v)) cfg.targets
      // mapAttrs' (n: v: nameValuePair "${n}.timer" (timerToUnit v)) cfg.timers;

    systemd.user.timers =
      # Generate timer units for all services that have a ‘startAt’ value.
      # Use `or []` for compatibility with the stub's `attrs` type which
      # does not guarantee `startAt` exists.
      mapAttrs (name: service: {
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = service.startAt;
      }) (filterAttrs (name: service: (service.startAt or [ ]) != [ ]) cfg.services);
  };
}
