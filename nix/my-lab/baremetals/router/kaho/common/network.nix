{ hostname, ... }:
{
  services.nscd = {
    enable = true;
  };
  networking = {
    useNetworkd = true;
    useHostResolvConf = false;
    hostName = hostname;
  };
}
