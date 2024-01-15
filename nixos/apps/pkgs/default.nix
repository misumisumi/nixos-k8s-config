{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    btrfs-progs # Btrfs filesystem utilities
    coreutils-full # GNU coreutils
    killall # Process killer
    lm_sensors # fan speed
    pciutils # Device utils
    traceroute # Track the network route
    usbutils # Tools for working with USB devices
  ];
}
