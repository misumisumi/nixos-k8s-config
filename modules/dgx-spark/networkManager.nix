{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.networking.networkmanager;
  # ini format identical to nixos/modules/services/networking/networkmanager.nix
  ini = pkgs.formats.ini { };
in
{
  ###### Host-delegated NetworkManager for Ubuntu/DGX Spark

  # This module intentionally does NOT import nixos/modules/services/networking/networkmanager.nix
  # because that upstream module manages systemd.services, systemd.packages, services.dbus/udev,
  # security.polkit and hardware.* which conflict with Ubuntu's apt-installed
  # NetworkManager (/lib/systemd/system/NetworkManager.service, /usr/sbin/NetworkManager,
  # /etc/dbus-1, /lib/udev/rules.d, polkit). See baremetals/roles/gpu-compute/haruna/stub.nix
  # for the previous workaround that still imported upstream and stubbed options.
  #
  # Instead we only manage declarative config files in /etc/NetworkManager via environment.etc
  # and leave systemd units, dbus, udev, polkit to the host (host-delegated).
  # - systemd.packages is NOT set, so /etc/systemd/system is not shadowed
  # - systemd.services.* are NOT created, so host's /lib/systemd/system units stay effective
  # - hardware / security.* / services.dbus are NOT managed

  options.networking.networkmanager = {
    enable = lib.mkEnableOption "NetworkManager (host-delegated, config only, no systemd units)";

    package = lib.mkPackageOption pkgs "networkmanager" { };

    settings = lib.mkOption {
      inherit (ini) type;
      default = { };
      description = ''
        Configuration added to the generated NetworkManager.conf.
        See https://developer.gnome.org/NetworkManager/stable/NetworkManager.conf.html
        or `man NetworkManager.conf`.
        This module only writes /etc/NetworkManager/NetworkManager.conf via environment.etc.
      '';
    };

    ensureProfiles = {
      profiles = lib.mkOption {
        type =
          with lib.types;
          attrsOf (submodule {
            freeformType = ini.type;
          });
        default = { };
        description = "Declarative NetworkManager profiles (keyfile) written to /etc/NetworkManager/system-connections via environment.etc.";
      };
      environmentFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "Files to load as EnvironmentFile for envsubst in profiles.";
      };
    };

    # Keep a subset of upstream options that affect config generation only (no systemd side-effects)
    unmanaged = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of interfaces not managed by NetworkManager (keyfile.unmanaged-devices).";
    };

    dhcp = lib.mkOption {
      type = lib.types.enum [
        "dhcpcd"
        "internal"
      ];
      default = "internal";
      description = "Which program should be used for DHCP.";
    };

    dns = lib.mkOption {
      type = lib.types.enum [
        "default"
        "dnsmasq"
        "systemd-resolved"
        "none"
      ];
      default = "default";
      description = "DNS (resolv.conf) processing mode.";
    };

    wifi.backend = lib.mkOption {
      type = lib.types.enum [
        "wpa_supplicant"
        "iwd"
      ];
      default = "wpa_supplicant";
      description = "Wi-Fi backend.";
    };

    wifi.powersave = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Whether to enable Wi-Fi power saving.";
    };
  };

  # Host-delegated networking stubs for haruna/network.nix (system-manager only defines firewall/enableIPv6)
  # nftables is now provided by ./nftables.nix and wg-quick by ./wg-quick.nix (proper typed options),
  # so we do NOT stub them here to avoid duplicate option definitions.
  options.systemd.network = lib.mkOption {
    type = lib.types.raw;
    default = { };
  };

  config = lib.mkIf cfg.enable {
    # Generate NetworkManager.conf without pulling upstream's systemd.services/packages.
    # Replicate upstream's configAttrs logic in minimal form (host-delegated).
    environment.etc =
      let
        # Minimal configAttrs: mirror upstream but without host-managed side-effects
        # (no hardware.wirelessRegulatoryDatabase, no polkit, no dbus).
        configAttrs = lib.recursiveUpdate {
          main = {
            plugins = "keyfile";
            inherit (cfg) dhcp dns;
            rc-manager = "unmanaged"; # host resolvconf is managed by Ubuntu, not Nix
          };
          keyfile = {
            unmanaged-devices = if cfg.unmanaged == [ ] then null else lib.concatStringsSep ";" cfg.unmanaged;
          };
          device = {
            "wifi.backend" = cfg.wifi.backend;
          };
        } cfg.settings;

        # Filter nulls like upstream does via recursiveUpdate + ini generation
        configFile = ini.generate "NetworkManager.conf" (
          lib.filterAttrsRecursive (n: v: v != null) configAttrs
        );
      in
      {
        "NetworkManager/conf.d/50-system-manager.conf".source = configFile;
      }
      // lib.optionalAttrs (cfg.ensureProfiles.profiles != { }) (
        # For host-delegated mode we write profiles to /etc/NetworkManager/system-connections
        # directly via environment.etc instead of a systemd service (ensure-profiles).
        lib.mapAttrs' (
          name: profile:
          lib.nameValuePair "NetworkManager/system-connections/${name}.nmconnection" {
            source = ini.generate "${name}.nmconnection" profile;
            mode = "0600";
          }
        ) cfg.ensureProfiles.profiles
      );

    # Explicitly do NOT create systemd units or touch host services.
    # If someone previously imported nixos's networkmanager.nix, these would conflict:
    #   systemd.services.NetworkManager, -wait-online, -dispatcher, -ensure-profiles
    #   systemd.packages, services.dbus.packages, services.udev.packages, security.polkit
    # We ensure they stay host-managed by not defining them at all.

    # Optional: warn if user expects host's NetworkManager to be restarted automatically.
    # Host's unit must be restarted manually after config change: `systemctl restart NetworkManager`.
    warnings = [
      "dgx-spark.networkManager: host-delegated mode – /etc/NetworkManager/NetworkManager.conf is managed declaratively, but systemd units (NetworkManager.service) remain host's /lib/systemd/system. Run `systemctl restart NetworkManager` manually after switch."
    ];
  };
}
