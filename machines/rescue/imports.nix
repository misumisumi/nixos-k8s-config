{ lib, ... }:
{
  imports = [
    ../common/default-user.nix
    ../common/network.nix
    ../common/nix-config.nix
    ../common/power-management.nix
    ../common/services.nix
    ../common/ssh.nix
    ../common/system-env.nix
  ];
}