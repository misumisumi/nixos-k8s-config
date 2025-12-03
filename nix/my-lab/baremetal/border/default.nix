{ self, ... }:
{
  imports = [
    self.nixosModules.kexec
  ];
}
