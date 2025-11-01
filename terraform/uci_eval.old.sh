uci set system.@system[0].hostname='ix2215'
uci commit system
/etc/init.d/system restart

uci set network.vlan21=device
uci set network.vlan21.name=eth1.21
uci set network.vlan21.ifname=eth1
uci set network.vlan21.vid=21

uci set network.vft200=device
uci set network.vft200.tyep=vrf
uci set network.vft200.name=vft-200
uci set network.vft200.table=200
uci add_list network.vft200.ports=eth1

uci set network.vft210=device
uci set network.vft210.tyep=vrf
uci set network.vft210.name=vft-210
uci set network.vft210.table=210
uci add_list network.vft210.ports=eth1.21

uci set network.lan=interface
uci set network.lan.ifname=eth1
uci set network.lan.netmask=255.255.255.0
uci set network.lan.ipaddr=10.0.200.1
uci set network.lan.proto=static
uci set network.lan.ip6addr=fd42:3a98:dc40:60c1::1/64
uci set network.lan.ip4table=200
uci set network.lan.ip6table=200

uci set network.lan_vlan21=interface
uci set network.lan_vlan21.ifname=eth1.21
uci set network.lan_vlan21.netmask=255.255.255.0
uci set network.lan_vlan21.ipaddr=10.0.210.1
uci set network.lan_vlan21.ip6addr=fd42:3a98:dc40:1::1/64
uci set network.lan_vlan21.ip4table=210
uci set network.lan_vlan21.ip6table=210

uci set network.lan2wan=rule
uci set network.lan2wan.src='lan'
uci set network.lan2wan.dest='wan'
uci set network.lan2wan.lookup='200'

uci commit network
/etc/init.d/network restart

uci set dhcp.lan.ignore=0
uci set dhcp.lan.start=10
uci set dhcp.lan.limit=245
uci set dhcp.lan.leasetime=1h
uci add_list dhcp.lan.dhcp_option='3,10.0.200.1'
uci add_list dhcp.lan.dhcp_option='6,10.0.200.1'
uci add_list dhcp.lan.dhcp_option='15,localdomain'
uci set dhcp.lan.dhcpv4='server'
# uci set dhcp.lan.dhcpv4='disabled'
uci add_list dhcp.lan.ra_default=1
uci set dhcp.lan.ra='server'
uci set dhcp.lan.ra_dns="1"
uci set dhcp.lan.dhcpv6='disabled'
uci set dhcp.lan.ndp='disabled'
uci set dhcp.lan.authoritative='1'

uci set dhcp.@dnsmasq[0]="dnsmasq"
uci set dhcp.@dnsmasq[0].domainneeded="1"
uci set dhcp.@dnsmasq[0].boguspriv="1"
uci set dhcp.@dnsmasq[0].filterwin2k="0"
uci set dhcp.@dnsmasq[0].localise_queries="1"
uci set dhcp.@dnsmasq[0].rebind_protection="1"
uci set dhcp.@dnsmasq[0].rebind_localhost="1"
uci set dhcp.@dnsmasq[0].local="/lan/"
uci set dhcp.@dnsmasq[0].domain="lan"
uci set dhcp.@dnsmasq[0].expandhosts="1"
uci set dhcp.@dnsmasq[0].nonegcache="0"
uci set dhcp.@dnsmasq[0].cachesize="1000"
uci set dhcp.@dnsmasq[0].authoritative="1"
uci set dhcp.@dnsmasq[0].readethers="1"
uci set dhcp.@dnsmasq[0].leasefile="/tmp/dhcp.leases"
uci set dhcp.@dnsmasq[0].resolvfile="/tmp/resolv.conf.d/resolv.conf.auto"
uci set dhcp.@dnsmasq[0].nonwildcard="1"
uci set dhcp.@dnsmasq[0].localservice="1"
uci set dhcp.@dnsmasq[0].ednspacket_max='1232'
uci set dhcp.@dnsmasq[0].filter_aaaa='0'
uci set dhcp.@dnsmasq[0].filter_a='0'
uci add_list dhcp.@dnsmasq[0].interface="lan"
uci add_list dhcp.@dnsmasq[0].notinterface="loopback"
uci commit dhcp
/etc/init.d/dnsmasq restart

uci set firewall.@zone[1].input='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart

opkg update
opkg install mtr curl
opkg install frr frr-watchfrr frr-ospfd frr-staticd frr-zebra frr-vtysh
