{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/container-config.nix") # common settings for container
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];
}
