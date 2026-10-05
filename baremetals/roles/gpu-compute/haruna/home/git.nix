{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    git-crypt
    git-ignore
    git-secret
    github-cli
  ];
  programs = {
    git = {
      enable = true;
      settings = {
        alias = {
          branch-clear = "!git branch --merged origin/HEAD | grep -vE '(HEAD|main|master)$' | xargs git branch -d";
          co-fixup = "commit --fixup";
          push-f = "push --force-with-lease";
          rebase-i = "rebase -i --autosquash";
          rebase-origin = "!git fetch origin --prune && git rebase origin/HEAD";
          tree = "log --graph --oneline --decorate --all";
        };
      };
      lfs.enable = true;
    };
  };
}
