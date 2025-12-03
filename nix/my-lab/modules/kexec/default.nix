{
  user,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];
  boot.initrd.compressor = "xz";
  services.getty.autologinUser = lib.mkForce "${user}";

  #NOTE: from https://github.com/nix-community/nixos-images/blob/main/nix/kexec-installer/module.nix
  system.build.kexecImageTarball =
    let
      tarName =
        if config.networking.hostName != "" then
          "${config.networking.hostName}.tar.gz"
        else
          "kexec-image.tar.gz";
      kexecRunScript = pkgs.replaceVarsWith {
        src = ./kexec-run.sh;
        isExecutable = true;
        replacements = {
          init = "${config.system.build.toplevel}/init";
          kernelParams = "${lib.escapeShellArgs config.boot.kernelParams}";
        };
      };
      # does not link with iptables enabled
      iprouteStatic = pkgs.pkgsStatic.iproute2.override { iptables = null; };
    in
    pkgs.runCommand "kexec-tarball" { } ''
      mkdir kexec $out
      cp "${config.system.build.netbootRamdisk}/initrd" kexec/initrd
      cp "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}" kexec/bzImage
      cp "${kexecRunScript}" kexec/run
      cp "${pkgs.pkgsStatic.kexec-tools}/bin/kexec" kexec/kexec
      cp "${iprouteStatic}/bin/ip" kexec/ip
      ${lib.optionalString (pkgs.hostPlatform == pkgs.buildPlatform) ''
        kexec/ip -V
        kexec/kexec --version
      ''}

      tar -czvf $out/${tarName} kexec
    '';
}
