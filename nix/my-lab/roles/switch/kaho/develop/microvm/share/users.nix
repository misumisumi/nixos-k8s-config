{ user, ... }:
{
  users.users = {
    ${user} = {
      password = "nixos";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPPrial/a0p8MAKxoY0HLTAqU/XKdVyU4RWfSs/LYPz1 sumi@mother"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOSAhHVFI2DWizyvGUC2Q8kw5902jVu+ozOJt9f4PY5Q renako.dev"
      ];
    };
    root = {
      password = "nixos";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOSAhHVFI2DWizyvGUC2Q8kw5902jVu+ozOJt9f4PY5Q renako.dev"
      ];
    };
  };
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    startWhenNeeded = false;
    settings = {
      KbdInteractiveAuthentication = true;
      PasswordAuthentication = true;
      X11Forwarding = false;
      PermitRootLogin = "yes";
    };
  };
}
