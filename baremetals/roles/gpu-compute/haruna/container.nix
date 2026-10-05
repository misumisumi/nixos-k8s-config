{
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) toShellVars;
in
{
  users.groups.podman = { };
  apt.packages = [
    #   "podman"
    #   "podman-compose"
    #   # for rootless containers
    #   "aardvark-dns"
    #   "catatonit"
    #   "slirp4netns"
    "uidmap"
  ];
  environment = {
    systemPackages = with pkgs; [
      podman
      podman-compose
    ];
    etc."containers/registries.conf.d/system-manager.conf".text = ''
      unqualified-search-registries = ["docker.io"]
      short-name-mode = "enforcing"
    '';
  };
  systemd = {
    packages = with pkgs; [
      podman
    ];
    sockets.podman = {
      wantedBy = [ "sockets.target" ];
      socketConfig.SocketGroup = "podman";
    };
    user.sockets.podman.wantedBy = [ "sockets.target" ];

    services.linger-users = {
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-logind.service" ];
      requires = [ "systemd-logind.service" ];

      script =
        let
          lingeringUserNames = [ user ];
          nonLingeringUserNames = [ ];
        in
        ''
          ${toShellVars { inherit lingeringUserNames nonLingeringUserNames; }}

          user_configured () {
              # Use `id` to check if the user exists rather than checking the
              # NixOS configuration, as it may be that the user has been
              # manually configured, which is permitted if users.mutableUsers
              # is true (the default).
              id "$1" >/dev/null
          }

          shopt -s dotglob nullglob
          for user in *; do
              if ! user_configured "$user"; then
                  # systemd has this user configured to linger despite them not
                  # existing.
                  echo "Removing linger for missing user $user" >&2
                  rm -- "$user"
              fi
          done

          if (( ''${#nonLingeringUserNames[*]} > 0 )); then
              ${pkgs.systemd}/bin/loginctl disable-linger "''${nonLingeringUserNames[@]}"
          fi
          if (( ''${#lingeringUserNames[*]} > 0 )); then
              ${pkgs.systemd}/bin/loginctl enable-linger "''${lingeringUserNames[@]}"
          fi
        '';

      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "systemd/linger";
        WorkingDirectory = "/var/lib/systemd/linger";
      };
    };
  };
}
