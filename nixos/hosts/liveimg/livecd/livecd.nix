{ user, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  users.users.root.password = "nixos";
  users.users.${user}.password = "nixos";
  environment.systemPackages = with pkgs; [
    rsync
  ];
}
