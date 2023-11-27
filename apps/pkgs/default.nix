{ pkgs, ... }:
with pkgs; [
  coreutils-full # GNU coreutils
  curl
  killall # Process killer
  lm_sensors # fan speed
  pciutils # Device utils
  screen # Separate terminal
  traceroute # Track the network route
  usbutils
  wget # Downloader
]
