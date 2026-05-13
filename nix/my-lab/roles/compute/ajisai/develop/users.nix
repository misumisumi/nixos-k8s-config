{ user, ... }:
{
  users.users = {
    "${user}" = {
      password = "nixos";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPPrial/a0p8MAKxoY0HLTAqU/XKdVyU4RWfSs/LYPz1 sumi@mother"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDiQd/aQAiLnEXYspAAAMYkTJhD5tMUd2gwip43qhUw amaori.dev"
      ];
    };
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPPrial/a0p8MAKxoY0HLTAqU/XKdVyU4RWfSs/LYPz1 sumi@mother"
      ];
    };
  };
}
