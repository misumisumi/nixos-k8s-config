{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Use raw boot.* (upstream system-manager defines boot as raw, so any
  # boot.kernelModules etc. is allowed without typed options). This avoids
  # fighting the parent `boot` raw leaf to become a branch.
  # config.boot may be undefined (raw with no default), so handle missing attrset.
  bootCfg = config.boot or { };
  cfgKernel = bootCfg.kernelModules or [ ];
  cfgBlacklist = bootCfg.blacklistedKernelModules or [ ];
  cfgExtra = bootCfg.extraModprobeConfig or "";

  kernelModulesConf = pkgs.writeText "50-system-manager.conf" ''
    ${lib.concatStringsSep "\n" cfgKernel}
  '';

  modprobeConfText = lib.concatStringsSep "\n" (
    (map (m: "blacklist ${m}") cfgBlacklist) ++ lib.optional (cfgExtra != "") cfgExtra
  );

  modprobeConf = pkgs.writeText "50-system-manager.conf" modprobeConfText;

  hasKernelModules = cfgKernel != [ ];
  hasModprobe = cfgBlacklist != [ ] || cfgExtra != "";
in
{
  ###### Host-delegated boot (kernel modules) for Ubuntu/DGX Spark
  # Port of nixos/modules/system/boot/kernel.nix:24 / 446 and
  # nixos/modules/system/boot/modprobe.nix:37 for system-manager host-delegated.
  # Uses raw boot.* (system-manager's boot = raw) so no typed options needed.
  # - Writes 50-system-manager.conf in both modules-load.d and modprobe.d so host
  #   can override with 60-*.conf .. 99-*.conf (lexical order, later wins).
  # - Overrides host's systemd-modules-load.service via drop-in (not full shadow)
  #   to add restartTriggers for immediate `modprobe` on `switch` (NixOS parity).
  #   Host's /lib/systemd/system/systemd-modules-load.service remains authoritative;
  #   system-manager only adds overrides.conf in /etc/systemd/system/...d/.

  config = lib.mkMerge [
    # Ensure config.boot exists (raw option has no default) so `boot` can be
    # accessed without "has no value" error. Children are handled via `or`.
    { boot = lib.mkDefault { }; }

    (lib.mkIf hasKernelModules {
      environment.etc."modules-load.d/50-system-manager.conf" = {
        source = kernelModulesConf;
        mode = "0644";
      };
    })

    (lib.mkIf hasModprobe {
      environment.etc."modprobe.d/50-system-manager.conf" = {
        text = modprobeConfText;
        mode = "0644";
      };
    })

    # (lib.mkIf (hasKernelModules || hasModprobe) {
    #   systemd.services.systemd-modules-load = {
    #     wantedBy = [ "multi-user.target" ];
    #     restartTriggers = lib.optionals hasKernelModules [ kernelModulesConf ]
    #       ++ lib.optionals hasModprobe [ modprobeConf ];
    #     serviceConfig.SuccessExitStatus = "0 1";
    #   };

    #   warnings = [
    #     "dgx-spark.boot: host-delegated – /etc/modules-load.d/50-system-manager.conf and /etc/modprobe.d/50-system-manager.conf are declarative (50, host can override with 60-*.conf). Kernel modules are loaded immediately via systemd-modules-load restartTriggers on switch; blacklist affects next modprobe only (already loaded modules need rmmod/reboot). initrd modules are not handled (host initramfs-tools)."
    #   ];
    # })
  ];
}
