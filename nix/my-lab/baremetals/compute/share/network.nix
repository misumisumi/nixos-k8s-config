{ hostname, ... }:
{
  services.nscd = {
    enable = true;
  };
  networking = {
    useNetworkd = true;
    hostName = hostname;
  };
}
