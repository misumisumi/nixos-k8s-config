{
  inputs,
  lib,
  pkgs,
  static,
  group,
  hostname,
  config,
  ...
}:
let
  inherit (builtins) filter;
  inherit (lib) removeSuffix;
  inherit (static.${group}.${hostname}) manageIP;
in
{
  system.activationScripts.putCerts4Cockpit = ''
    ln -sf /var/lib/certs/server/server.key /etc/cockpit/ws-certs.d/server.key
    ln -sf /var/lib/certs/server/server.crt /etc/cockpit/ws-certs.d/server.cert
  '';

  #TODO: 26.04がメジャーリリースされた段階でこれを削除
  disabledModules = [ "services/monitoring/cockpit.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/cockpit.nix" ];

  environment.systemPackages = [ config.services.cockpit.package ];

  services = {
    pcp = {
      enable = true;
      package = inputs.pcp.packages.${pkgs.stdenv.hostPlatform.system}.pcp.overrideAttrs (old: {
        configureFlags = (filter (x: !lib.hasPrefix "--with-logdir" x) old.configureFlags) ++ [
          "--with-logdir=/var/log/pcp"
        ];
        postPatch = old.postPatch or "" + ''
          substituteInPlace GNUmakefile \
            --replace-fail '$(INSTALL) -m 775 -d $(PCP_LOG_DIR)' ""
          substituteInPlace src/pmfind/GNUmakefile \
            --replace-fail '$(INSTALL) -m 775 -o $(PCP_USER) -g $(PCP_GROUP) -d $(PCP_LOG_DIR)/pmfind' ""
          substituteInPlace src/pmcd/GNUmakefile \
            --replace-fail '$(INSTALL) -m 755 -d $(PCP_LOG_DIR)/pmcd' ""
          substituteInPlace src/pmproxy/GNUmakefile \
            --replace-fail '$(INSTALL) -m 775 -o $(PCP_USER) -g $(PCP_GROUP) -d $(PCP_LOG_DIR)/pmproxy' ""
          substituteInPlace src/pmie/GNUmakefile \
            --replace-fail '$(INSTALL) -m 775 -o $(PCP_USER) -g $(PCP_GROUP) -d $(PCP_LOG_DIR)/pmie' ""
          substituteInPlace src/pmlogger/GNUmakefile \
            --replace-fail '$(INSTALL) -m 775 -o $(PCP_USER) -g $(PCP_GROUP) -d $(PCP_LOG_DIR)/pmlogger' "" \
            --replace-fail '$(INSTALL) -m 775 -o $(PCP_USER) -g $(PCP_GROUP) -d $(PCP_SA_DIR)' ""
        '';
        nativeBuildInputs =
          (filter (x: x != pkgs.python3 && x != pkgs.python3.pkgs.setuptools) old.nativeBuildInputs)
          ++ [
            config.services.cockpit.package.passthru.python3Packages.python
            config.services.cockpit.package.passthru.python3Packages.python.pkgs.setuptools
          ];
        buildInputs =
          (filter (x: x != pkgs.python3 || x != pkgs.python3.pkgs.setuptools) old.buildInputs)
          ++ [
            config.services.cockpit.package.passthru.python3Packages.python
          ];
      });
      preset = "standalone";
      openFirewall = true;
    };

    #NOTE: VMでCPU温度が取れず、metricsの収集ができないため、グラフ描画はされない(要実機での確認)
    cockpit = rec {
      enable = true;
      port = 9090;
      plugins = with pkgs; [
        cockpit-files
        cockpit-machines
      ];
      package = pkgs.cockpit.overrideAttrs (old: {
        postPatch = old.postPatch or "" + ''
          substituteInPlace vendor/ferny/src/ferny/interaction_client.py \
            --replace-fail "#!/usr/bin/python3" "#!${config.services.cockpit.package.passthru.python3Packages.python}/bin/python"
          substituteInPlace src/cockpit/beiboot.py \
            --replace-fail "'python3'" "'${config.services.cockpit.package.passthru.python3Packages.python}/bin/python'"
        '';
        postFixup = old.postFixup or "" + ''
          wrapProgram $out/bin/cockpit-bridge \
            --prefix LD_LIBRARY_PATH : "${config.services.pcp.package}/lib"
        '';
        passthru = old.passthru // {
          cockpitPath = old.passthru.cockpitPath ++ [ config.services.pcp.package ];
        };
      });
      openFirewall = true;
      allowed-origins = [
        "https://${removeSuffix "/24" manageIP}:${toString port}"
        "https://${hostname}:${toString port}"
        "https://${hostname}.home:${toString port}"
      ];
    };
  };
}
