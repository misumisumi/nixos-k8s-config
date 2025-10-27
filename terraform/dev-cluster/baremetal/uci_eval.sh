#!/usr/bin/env ash

INSTANCES="ipxe first_stage"
VLANIDS="200 210"
VFTIDS="200 210"

uci set system.@system[0].hostname='ix2215'
uci commit system
/etc/init.d/system restart

COUNT=0
for INST in ${INSTANCES}; do
  COUNT=$((COUNT + 1))
  VLANID=$(echo "${VLANIDS}" | cut -d' ' -f${COUNT})
  VFTID=$(echo "${VFTIDS}" | cut -d' ' -f${COUNT})

  if [ "${VLANID}" -eq 200 ]; then
    uci set network.vft${VFTID}=device
    uci set network.vft${VFTID}.tyep=vrf
    uci set network.vft${VFTID}.name=vft-${VFTID}
    uci set network.vft${VFTID}.table=${VFTID}
    uci add_list network.vft${VFTID}.ports=eth1

    uci set network.lan_${INST}=interface
    uci set network.lan_${INST}.ifname="eth1"
  else
    uci set network.vlan${VLANID}=device
    uci set network.vlan${VLANID}.name=eth1.${VLANID}
    uci set network.vlan${VLANID}.ifname=eth1
    uci set network.vlan${VLANID}.vid=${VLANID}

    uci set network.vft${VFTID}=device
    uci set network.vft${VFTID}.tyep=vrf
    uci set network.vft${VFTID}.name=vft-${VFTID}
    uci set network.vft${VFTID}.table=${VFTID}
    uci add_list network.vft${VFTID}.ports="eth1.${VLANID}"

    uci set network.lan_${INST}=interface
    uci set network.lan_${INST}.ifname="eth1.${VLANID}"
  fi

  uci set network.lan_${INST}.netmask=255.255.255.0
  uci set network.lan_${INST}.ipaddr="10.0.${VLANID}.1"
  uci set network.lan_${INST}.proto=static
  uci set network.lan_${INST}.ip4table=${VFTID}
  uci set network.lan_${INST}.ip6table=${VFTID}
  uci set network.lan_${INST}.ip6addr="fd42:3a98:dc40:$(printf "%x" "${VLANID}")::1/64"
  uci set network.lan_${INST}.ip6prefix="fd42:3a98:dc40:$(printf "%x" "${VLANID}")::/64"
done

while uci -q delete dhcp.@dnsmasq[0]; do :; done
while uci -q delete dhcp.@dhcp[0]; do :; done
COUNT=0
for INST in ${INSTANCES}; do
  COUNT=$((COUNT + 1))
  VLANID=$(echo "${VLANIDS}" | cut -d' ' -f${COUNT})
  VFTID=$(echo "${VFTIDS}" | cut -d' ' -f${COUNT})

  uci set dhcp.dns_${INST}="dnsmasq"
  uci set dhcp.dns_${INST}.domainneeded="1"
  uci set dhcp.dns_${INST}.boguspriv="1"
  uci set dhcp.dns_${INST}.filterwin2k="0"
  uci set dhcp.dns_${INST}.localise_queries="1"
  uci set dhcp.dns_${INST}.rebind_protection="1"
  uci set dhcp.dns_${INST}.rebind_localhost="1"
  uci set dhcp.dns_${INST}.local="/${INST}/"
  uci set dhcp.dns_${INST}.domain="${INST}"
  uci set dhcp.dns_${INST}.expandhosts="1"
  uci set dhcp.dns_${INST}.nonegcache="0"
  uci set dhcp.dns_${INST}.cachesize="1000"
  uci set dhcp.dns_${INST}.authoritative="1"
  uci set dhcp.dns_${INST}.readethers="1"
  uci set dhcp.dns_${INST}.leasefile="/tmp/dhcp.leases.${INST}"
  uci set dhcp.dns_${INST}.resolvfile="/tmp/resolv.conf.d/resolv.conf.auto.${INST}"
  uci set dhcp.dns_${INST}.nonwildcard="1"
  uci set dhcp.dns_${INST}.localservice="1"
  uci set dhcp.dns_${INST}.ednspacket_max='1232'
  uci set dhcp.dns_${INST}.filter_aaaa='0'
  uci set dhcp.dns_${INST}.filter_a='0'
  uci add_list dhcp.dns_${INST}.interface="lan_${INST}"
  uci add_list dhcp.dns_${INST}.notinterface="loopback"
done

COUNT=0
for INST in ${INSTANCES}; do
  COUNT=$((COUNT + 1))
  VLANID=$(echo "${VLANIDS}" | cut -d' ' -f${COUNT})
  VFTID=$(echo "${VFTIDS}" | cut -d' ' -f${COUNT})
  uci set dhcp.${INST}="dhcp"
  uci set dhcp.${INST}.instance="dns_${INST}"
  uci set dhcp.${INST}.interface="lan_${INST}"
  uci set dhcp.${INST}.start="10"
  uci set dhcp.${INST}.limit="245"
  uci set dhcp.${INST}.leasetime="1h"
  uci set dhcp.${INST}.ra='server'
  uci set dhcp.${INST}.ra_dns="1"
  uci set dhcp.${INST}.dhcpv6='disabled'
  uci set dhcp.${INST}.ndp='disabled'
  uci set dhcp.${INST}.authoritative='1'
  uci add_list dhcp.${INST}.dhcp_option="3,10.0.${VLANID}.1"
  uci add_list dhcp.${INST}.dhcp_option="6,10.0.${VLANID}.1"
  uci add_list dhcp.${INST}.dhcp_option="15,${INST}"
done

uci -q delete dhcp.@dnsmasq[0].notinterface

uci commit network
/etc/init.d/network restart

uci commit dhcp
/etc/init.d/dnsmasq restart

while uci -q delete firewall.@zone[0]; do :; done
while uci -q delete firewall.@forwarding[0]; do :; done

uci set firewall.wan=zone
uci set firewall.wan.name=wan
uci add_list firewall.wan.network=wan
uci add_list firewall.wan.network=wan6
uci set firewall.wan.input="ACCEPT"
uci set firewall.wan.output="ACCEPT"
uci set firewall.wan.forward="REJECT"

uci set network.lan2wan=rule
uci set network.lan2wan.src='lan_ipxe'
uci set network.lan2wan.dest='wan'
uci set network.lan2wan.lookup='200'

COUNT=0
for INST in ${INSTANCES}; do
  COUNT=$((COUNT + 1))
  VLANID=$(echo "${VLANIDS}" | cut -d' ' -f${COUNT})
  VFTID=$(echo "${VFTIDS}" | cut -d' ' -f${COUNT})

  uci set firewall.${INST}=zone
  uci set firewall.${INST}.name=${INST}
  uci add_list firewall.${INST}.network=lan_${INST}
  uci add_list firewall.${INST}.network=lan6_${INST}
  uci set firewall.${INST}.input="ACCEPT"
  uci set firewall.${INST}.output="ACCEPT"
  uci set firewall.${INST}.forward="ACCEPT"
done
uci commit firewall
/etc/init.d/firewall restart
opkg update
opkg install mtr curl
opkg install frr frr-watchfrr frr-ospf6d frr-staticd frr-zebra
