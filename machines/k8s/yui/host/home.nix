{
  lib,
  hostname,
  pkgs,
  ...
}: {
  programs.neovim.useMyDots.enable = true;
  programs.editorconfig.useMyDots.enable = true;

  imports =
    import ../../apps/userWide {
      inherit lib hostname;
      isLarge = true;
    }
    ++ (import ../../apps/userWide/wm/qtile);

  home = {
    installCommonPkgs = {
      enable = true;
      isLarge = true;
    };
    packages = import ../../apps/userWide/pkgs {
      inherit lib pkgs;
      isFull = true;
    };
  };
}