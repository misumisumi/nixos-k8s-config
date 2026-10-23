{ pkgs, ... }:
let
  sync = pkgs.writeShellScript "home40g-vf-macfilter" ''
    set -euo pipefail
    export LC_ALL=C

    state=/run/home40g-vf-macfilter
    mkdir -p "$state"
    desired="$state/desired"
    managed="$state/managed"
    : > "$desired"
    [ -e "$managed" ] || : > "$managed"

    until ${pkgs.iproute2}/bin/ip link show enp0s2f0 >/dev/null 2>&1 &&
          ${pkgs.iproute2}/bin/ip link show enp0s4f0 >/dev/null 2>&1; do
      sleep 2
    done

    while :; do
      {
        printf '%s\n' "02:03:aa:aa:00:0a"
        ${pkgs.iproute2}/bin/bridge fdb show dev enp0s2f0 |
          ${pkgs.gawk}/bin/awk '$2 == "vlan" && $3 == "10" && $4 == "master" && $6 != "permanent" { print $1 }'
      } | sort -u > "$desired"

      while read -r mac; do
        [ -n "$mac" ] || continue
        ${pkgs.iproute2}/bin/bridge fdb replace "$mac" dev enp0s4f0 self
      done < "$desired"

      comm -23 "$managed" "$desired" | while read -r mac; do
        [ -n "$mac" ] || continue
        ${pkgs.iproute2}/bin/bridge fdb del "$mac" dev enp0s4f0 self || true
      done

      cp "$desired" "$managed"
      sleep 5
    done
  '';
in
{
  systemd.services.home40g-vf-macfilter = {
    description = "Sync home VLAN 10 client and anycast MACs to the 40G VF filter";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-networkd.service" ];
    wants = [ "systemd-networkd.service" ];
    startLimitIntervalSec = 0;
    path = with pkgs; [
      iproute2
      gawk
      coreutils
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = sync;
      Restart = "always";
      RestartSec = 5;
      RuntimeDirectory = "home40g-vf-macfilter";
      RuntimeDirectoryPreserve = "yes";
      TimeoutStopSec = 5;
    };
  };
}
