{ hostname, ... }:
{
  services = {
    nscd = {
      enable = true;
    };
  };
  networking = {
    hostName = "${hostname}";
  };
}
