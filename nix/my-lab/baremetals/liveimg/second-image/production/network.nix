{
  static,
  ...
}:
{
  systemd = {
    network = {
      enable = true;
      netdevs = {
        "bond-en" = {
          netdevConfig = {
            Kind = "bond";
            Name = "bond-en";
          };
          bondConfig = {
            Mode = "active-backup";
            MIIMonitorSec = "1s";
            PrimaryReselectPolicy = "always";
            UpDelaySec = "0";
            DownDelaySec = "0";
          };
        };
      };
      networks = {
        "10-en" = {
          name = "en*";
          bond = [ "bond-en" ];
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "10-ib" = {
          name = "ib*";
          bond = [ "bond-en" ];
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "20-bond-en" = {
          name = "bond-en";
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "20-bond-ib" = {
          name = "bond-ib";
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
      };
    };
  };
}
