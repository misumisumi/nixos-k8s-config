{
  lib,
  pkgs,
  ...
}:
{
  boot = {
    extraModulePackages = [ pkgs.drbd9-dkms ];
    kernelModules = [
      "drbd"
    ];
  };
}
