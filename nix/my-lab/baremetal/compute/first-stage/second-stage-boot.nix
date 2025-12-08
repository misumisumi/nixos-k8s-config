{ self, ... }:
{
  imports = [ self.nixosModules.diskless ];
  services.diskless.kexec = {
    enable = true;
    serverURL = "http://tiny-router.kexec";
    imageFile = "kexec-test.tar.gz";
  };
}
