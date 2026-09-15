{ lib, config, ... }:
let
  inherit (lib) importTOML;
in
{
  programs = {
    bash.initExtra = ''
      if [[ $TERM != "dumb" && $TERM != "linux" ]]; then
        eval "$("${config.home.profileDirectory}/bin/starship" init bash --print-full-init)"
      fi
    '';
    starship = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
      settings = importTOML ./theme.toml;
    };
  };
}
