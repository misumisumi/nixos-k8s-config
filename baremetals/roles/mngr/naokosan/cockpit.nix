{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) makeBinPath;
in
{
  imports = [
    ../../share/settings/cockpit.nix
  ];
  services.cockpit.settings = {
    WebService = {
      LoginTo = true;
    };
    Ssh-Login = {
      connectToUnknownHosts = true;
      Command =
        let
          beiboot = pkgs.writeShellScript "cockpit-beiboot" ''
            export PATH=${
              makeBinPath [
                config.services.cockpit.package.passthru.python3Packages.python
                config.services.openssh.package
              ]
            }
            export PYTHONPATH=${config.services.cockpit.package}/${config.services.cockpit.package.passthru.python3Packages.python.sitePackages}
            ${config.services.cockpit.package.passthru.python3Packages.python}/bin/python -m cockpit.beiboot "$@"
          '';
        in
        "${beiboot}";
    };
  };
}
