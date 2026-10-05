{
  imports = [
    ./btop.nix
    ./starship
    ./tmux.nix
    ./yazi
  ];
  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      historyControl = [ "ignoreboth" ];
      profileExtra = "";
      shellOptions = [
        "-histappend"
        "checkwinsize"
        "extglob"
        "globstar"
        "checkjobs"
      ];
      historyIgnore = [
        "builtin"
        "cd"
        "history"
        "kill"
        "ls"
        "mkdir"
        "pkill"
        "rm"
        # git commands
        "git branch"
        "git checkout"
        "git log"
        "git pull"
        "git status*"
        # zoxide
        "z"
        "zi"
      ];
    };
  };
}
