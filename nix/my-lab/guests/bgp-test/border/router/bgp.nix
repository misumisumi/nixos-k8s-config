{
  config,
  pkgs,
  ...
}:

{
  # FRR (Free Range Routing) を有効にする
  services.frr = {
    bgpd.enable = true;
    # FRRの設定はconfigオプションで直接記述
    config = ''
      router bgp 65002
        bgp router-id 172.16.0.2
        bgp log-neighbor-changes
        bgp bestpath as-path multipath-relax
        neighbor SERVER peer-group
        neighbor SERVER remote-as external
        neighbor SERVER advertisement-interval 0
        neighbor SERVER timers 1 3
        neighbor SERVER timers connect 5
        neighbor SERVER capability extended-nexthop
        neighbor enp0s3 interface peer-group SERVER
        neighbor enp0s4 interface peer-group SERVER

      address-family ipv4 unicast
        redistribute connected route-map Redistribute_dummy_interface
        neighbor SERVER soft-reconfiguration inbound
        neighbor SERVER prefix-list Dummy0 out
        neighbor SERVER prefix-list Private_IP_Addresses in
        neighbor SERVER route-map SERVER_IN in
      exit-address-family

      ip prefix-list Private_IP_Addresses seq 5 permit 10.0.0.0/8 le 32
      ip prefix-list Private_IP_Addresses seq 10 permit 172.16.0.0/12 le 32
      ip prefix-list Private_IP_Addresses seq 15 permit 192.168.0.0/16 le 32
      ip prefix-list Dummy0 seq 5 permit 172.16.0.2/32

      route-map Redistribute_dummy_interface permit 10
        match interface dummy0
      exit

      route-map Dummy_SET_SRC permit 10
        match tag 101
        set src 172.16.0.2
      exit

      route-map SERVER_IN permit 10
        set tag 101
      exit


      ip protocol bgp route-map Dummy_SET_SRC
    '';
    # address-family ipv4 unicast
    #   neighbor fabric activate
    # exit-address-family
    # neighbor br-40g.main interface peer-group fabric
    # neighbor br-10g.main interface peer-group fabric
    # neighbor br-40g.main weight 200
    # neighbor br-10g.main weight 100
    # address-family ipv6 unicast
    #   neighbor fabric activate
    # exit-address-family
  };

  # ホスト自身のオーバーレイIPアドレスを設定する場合 (オプション)
  # networking.extraNetworks = {
  #   "lo:0" = {
  #     ipv6.addresses = [
  #       { address = "2001:db8:spine::1"; prefixLength = 64; } # 例: ホストのオーバーレイIP
  #     ];
  #   };
  # };
}
