{
  self,
  static,
  lib,
  isDev,
  ...
}:
let
  inherit (lib) removePrefix;
  inherit (static.mngr.image-server) manageIP;
  variant = if isDev then "develop" else "production";
in
{
  imports = [ self.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://${removePrefix "/24" manageIP}/kexec";
    fallBackImage = "kexec/${variant}/second-image/nixos-kexec.tar.xz";
  };
}
