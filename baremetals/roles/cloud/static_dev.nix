{
  cloud = {
    oci = {
      # dev は x86_64（検証用の incus VM、ネイティブ・エミュ無し）。
      # OCI 実機は本番側（static.nix）が aarch64。
      system = "x86_64-linux";
      user = "renako";
      hostname = "oci";
      # dev は incus の 1 インスタンス。fake-isp の wan 側（疑似インターネット）= 10.150.150.0/24 に接続。
      networks = {
        wan = {
          IF = "enp5s0"; # incus VM の NIC（作成後に ip a で確認・調整）
          address = "10.150.150.10/24";
          gateway = "10.150.150.1";
        };
      };
      # dev 用 WireGuard トポロジ（endpoint は lab の疑似インターネット IP）。
      # peers は border-router(自宅LAN=192.168.20.0/24) + cellphone のみ。
      # k8s node-a/node-b は本番のみ。
      wireguard = {
        subnet = "10.250.0.0/24";
        serverAddress = "10.250.0.1/24";
        listenPort = 51820;
        endpoint = "10.150.150.10";
        publicKey = "8sSo2LKRL6HGTGkibSW9g22Uvi4zeqZQzB+Ol9vKkFs=";
        peers = {
          "border-router" = {
            address = "10.250.0.3";
            publicKey = "e75HAR3m8GYR4d+6f7YfVmBK76mwYpLkxJZLZBYuxDE=";
            allowedIPs = [ "192.168.20.0/24" ];
          };
          "cellphone" = {
            address = "10.250.0.2";
            publicKey = "fOeXNNN+BcLFnFpRz2FPxt7QnfwidKryvjv58tc5Imc=";
            allowedIPs = [ ];
          };
        };
      };
    };
  };
}