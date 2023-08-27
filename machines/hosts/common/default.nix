{ pkgs, ... }: {
  imports = [
    ./boot.nix
    ./default-user.nix
    ./lxd.nix
    ./network.nix
    ./nix-conf.nix
    ./services.nix
    ./ssh.nix
    ./system-env.nix
  ];
  environment.systemPackages = with pkgs; [
    coreutils-full # GNU coreutils
    killall # Process killer
    pciutils # Device utils
    usbutils
    traceroute # Track the network route
    lsof # check port
    btop # System monitor
    neofetch # Fetch system info
  ];
}
