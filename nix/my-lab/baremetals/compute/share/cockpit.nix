{
  static,
  group,
  hostname,
  ...
}:
let
  inherit (builtins) head;
  inherit (static.${group}.${hostname}) address;
in
{
  services.cockpit = rec {
    enable = true;
    port = 9090;
    openFirewall = true;
    allowed-origins = [
      "https://${head address}:${toString port}"
      "https://${hostname}:${toString port}"
      "https://${hostname}.home:${toString port}"
    ];
    settings = {
      WebService = {
        LoginTo = false;
      };
    };
  };
  systemd.tmpfiles.rules = [
    "d /etc/cockpit/machines.d 0766 root root -"
  ];
}
