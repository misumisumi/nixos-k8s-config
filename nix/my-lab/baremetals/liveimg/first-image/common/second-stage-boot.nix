{ self, ... }:
{
  imports = [ self.nixosModules.diskless ];
  # services.diskless.kexec = {
  #   enable = true;
  #   serverURL = "http://image-server.kexec";
  #   imageFile = "kexec-test.tar.gz";
  # };
}
