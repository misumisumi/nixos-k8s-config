{ pkgs, ... }:
{
  imports = [
    ../share
    ./bgp.nix
    ./network.nix
  ];
  services.openssh = {
    enable = true;
    # startWhenNeeded = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      # PermitEmptyPasswords = true;
      # UsePAM = false;
    };
  };
  users.users.root = {
    password = "nixos";
    # openssh.authorizedKeys = [ ];
  };
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
    tshark
    tcpdump
  ];
}
