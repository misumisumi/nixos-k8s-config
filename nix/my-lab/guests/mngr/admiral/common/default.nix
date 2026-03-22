{
  self,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./cockpit.nix
    ../../../share/settings/nix
    ../../../share/settings/locale
    # ../../share/settings/ssh
  ];
}
