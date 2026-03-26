{ self, ... }:
{
  imports = [ self.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://image-server.initial.home/kexec";
    fallBackImage = "second-image/nixos-kexec.tar.xz";
  };
}
