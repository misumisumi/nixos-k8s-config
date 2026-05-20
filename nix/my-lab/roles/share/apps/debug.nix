{ pkgs, user, ... }:
{
  environment.systemPackages = with pkgs; [
    tcpdump
  ];
  users.groups = {
    wireshark.members = [
      user
    ];
  };

  programs.wireshark = {
    enable = true;
    package = pkgs.tshark;
    dumpcap.enable = true;
    usbmon.enable = true;
  };
}
