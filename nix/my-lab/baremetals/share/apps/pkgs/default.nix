{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # utilities
    btrfs-progs # Btrfs filesystem utilities
    coreutils-full # GNU coreutils
    fd # Find files by name and other attributes
    killall # Process killer
    lm_sensors # fan speed
    pciutils # Device utils
    repgrep # Fast search tool
    yazi # terminal file manager
    # network utilities
    dig # DNS lookup utility
    dnsutils # DNS utilities
    ethtool # Network interface configuration
    socat # Multipurpose relay (SOcket CAT)
    traceroute # Track the network route
  ];
}
