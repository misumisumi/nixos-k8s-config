{ pkgs, ... }:
{
  services.linstor = {
    controller.enable = true;
    client.enable = true;
  };
}
