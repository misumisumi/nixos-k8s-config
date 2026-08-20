{
  writeShellApplication,
  iproute2,
  systemd,
  lib,
}:
let
  inherit (lib) replaceStrings head splitString;
  static = import ../roles/static_dev.nix;

  dnsIP = head (splitString "/" static.shared.dns.networks.manage.address);
  domain = static.dev.env.domain;
  nic = replaceStrings [ "_" ] [ "-" ] static.dev.env.nic;
  vip = static.dev.env.cilium_lb;
  leafGW = static.fake.leaf.bgp.k8sSegmentIP;
in
writeShellApplication {
  name = "setup-dev-env";
  runtimeInputs = [
    iproute2
    systemd
  ];
  text = ''
    set -e

    # su 環境や直接rootログインでは実行しない
    if [ -z "''${SUDO_USER:-}" ]; then
      echo "Run this with: sudo $0 {add|del}"
      exit 1
    fi

    case "''${1:-}" in
      add)
        ip route add "${vip}/32" via "${leafGW}"
        resolvectl dns "${nic}" "${dnsIP}"
        resolvectl domain "${nic}" "${domain}"
        echo "Added route for ${vip} via ${leafGW}"
        echo "Set DNS ${dnsIP} on ${nic} for ${domain}"
        ;;
      del)
        resolvectl revert "${nic}" 2>/dev/null || true
        ip route del "${vip}/32" 2>/dev/null || true
        echo "Removed DNS settings and route for ${vip}"
        ;;
      *)
        echo "Usage: sudo $0 {add|del}"
        exit 1
        ;;
    esac
  '';
}
