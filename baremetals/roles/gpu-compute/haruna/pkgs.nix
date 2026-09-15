{ pkgs, ... }:
{
  apt.packages = [
    "mosh"
  ];
  environment.systemPackages = with pkgs; [
    btop
    fzf
    python3Packages.huggingface-hub
    starship
    yazi
    zoxide
  ];
}
