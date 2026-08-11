{
  lib,
  config,
  static,
  group,
  hostname,
  isDev,
  ...
}:
let
  inherit (lib) hasAttr optionalAttrs;
in
{
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  services.openssh = {
    enable = true;
    generateHostKeys = false;
    ports = [ 22 ];
    startWhenNeeded = false;
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = isDev;
      X11Forwarding = false;
      PermitRootLogin = if isDev then "yes" else "no";
    };
  }
  // optionalAttrs (hasAttr "manageIP" static.${group}.${hostname}) {
    listenAddresses = [
      {
        addr = static.${group}.${hostname}.manageIP;
        port = 22;
      }
    ];
  };
  systemd.services.sshd = {
    serviceConfig = {
      # 失敗時に自動リトライ。間隔は10s→20s→40s→80s→160sと指数関数的に増加
      RestartSec = 10;
      RestartSteps = 5;
    };
    unitConfig = {
      # NOTE: error: Bind to port 22 on <ip adddr> failed: Cannot assign requested address.への対処
      StartLimitBurst = 5;
      StartLimitIntervalSec = 300;
    };
  };
}
