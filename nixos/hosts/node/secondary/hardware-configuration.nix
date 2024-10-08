# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config
, lib
, pkgs
, modulesPath
, hostname
, cpu_bender
, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "uas" "sd_mod" ];
      kernelModules = [ "dm-snapshot" ];
    };
  };
  hardware.cpu.${cpu_bender}.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
