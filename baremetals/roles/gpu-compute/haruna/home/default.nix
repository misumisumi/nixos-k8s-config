{ pkgs, ... }:
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
      bashrcExtra = "";
      initExtra = ''
        function share_history {  # 以下の内容を関数として定義
            history -a  # .bash_historyに前回コマンドを1行追記
            history -c  # 端末ローカルの履歴を一旦消去
            history -r  # .bash_historyから履歴を読み込み直す
        }
        PROMPT_COMMAND="share_history; ''${PROMPT_COMMAND}"  # 上記関数をプロンプト毎に自動実施
        # Enable ble.sh
        [[ $- == *i* ]] && source -- ${pkgs.blesh}/share/blesh/ble.sh --attach=none

        [[ ! ''${BLE_VERSION-} ]] || ble-attach
        # カーソル形状をビーム（縦棒）に変更
        echo -ne "\e[6 q"
      '';
      logoutExtra = "";
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
