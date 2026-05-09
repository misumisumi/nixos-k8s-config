leaf=4
#############################
## type-5 vrf10001 / l3vni 10001 ##
#############################
ip link add vrf10001 type vrf table 10001
ip addr add 127.0.0.1/8 dev vrf10001
ip link set vrf10001 up

ip link add br10001 type bridge stp_state 0 forward_delay 0
ip link set br10001 master vrf10001 addrgenmode none
ip link set br10001 addr aa:bb:cc:10:3${leaf}:21
ip link add vni10001 type vxlan local 10.1.254.${leaf} dstport 4789 id 10001 nolearning
ip link set vni10001 master br10001 addrgenmode none
ip link set vni10001 type bridge_slave neigh_suppress on learning off
ip link set br10001 up
ip link set vni10001 up

ip link add lo10001 type dummy
ip link set lo10001 master vrf10001
ip addr add 172.16.10.${leaf}/32 dev lo10001
ip link set lo10001 up

###############
## l2vni 110 ##
###############
ip link add br10 type bridge
ip link set br10 master vrf10001
ip link set br10 addr aa:bb:cc:00:00:6e
ip addr add 172.16.11.${leaf}/24 dev br10
ip link add vni110 type vxlan local 10.1.254.${leaf} dstport 4789 id 110 nolearning
ip link set vni110 master br10 addrgenmode none
ip link set vni110 type bridge_slave neigh_suppress on learning off
ip link set vni110 up
ip link set br10 up

#############################
## ip-vrf vrf10002 / l3vni 10002 ##
#############################
ip link add vrf10002 type vrf table 10002
ip addr add 127.0.0.1/8 dev vrf10002
ip link set vrf10002 up

ip link add lo10002 type dummy
ip link set lo10002 vrf vrf10002
ip addr add 172.16.20.${leaf}/32 dev lo10002
ip link set lo10002 up

ip link add br10002 type bridge stp_state 0 forward_delay 0
ip link set br10002 vrf vrf10002 addrgenmode none
ip link set br10002 addr aa:bb:cc:10:4${leaf}:21

ip link add vni10002 type vxlan local 10.1.254.${leaf} dstport 4789 id 10002 nolearning
ip link set vni10002 master br10002
ip link set vni10002 type bridge_slave neigh_suppress on learning off

ip link set vni10002 up
ip link set br10002 up

##############################
leaf=5
ip link add br0 type bridge vlan_filtering 1 vlan_default_pvid 0
# the key setting for SVD configuration is "external"
# "vnifilter" isn't strictly necessary but is correct
ip link add vxlan0 type vxlan dstport 4789 local 10.1.254.${leaf} nolearning external vnifilter
ip link set br0 addrgenmode none
ip link set vxlan0 addrgenmode none master br0
ip link set br0 address b2:4b:95:b6:a4:f${leaf}
ip link set vxlan0 address b2:4b:95:b6:a4:f${leaf}
ip link set br0 up
ip link set vxlan0 up
bridge link set dev vxlan0 vlan_tunnel on neigh_suppress on learning off

ip link add vrf10001 type vrf table 10001
ip link set vrf10001 up

#############################
## ip-vrf vrf1 / l3vni 100 ##
#############################
# Choose any arbitrary VLAN for L3VNIs, since it never leaves the device
# as long as it doesn't collide with another VLAN. It's used solely to
# bind into a routing table (VRF)
bridge vlan add dev br0 vid 1001 self
bridge vlan add dev vxlan0 vid 1001
bridge vni add dev vxlan0 vni 10001                                     # add vni if using vnifilter
bridge vlan add dev vxlan0 vid 1001 tunnel_info id 10001                # map vlan to vni
ip link add vrf10001br link br0 type vlan id 1001                       # create vlan on top of bridge
ip link set vrf10001br address b2:4b:95:b6:a4:f${leaf} addrgenmode none # set L3VNI devices to routermac and no address
ip link set vrf10001br master vrf10001                                  # bind the device to the correct VRF, no address for L3VNI

###############
## l2vni 110 ##
###############
bridge vlan add dev br0 vid 10 self
bridge vlan add dev vxlan0 vid 10
bridge vni add dev vxlan0 vni 10011
bridge vlan add dev vxlan0 vid 10 tunnel_info id 10011
ip link add vlan10 link br0 type vlan id 10
ip link set vlan10 master vrf10001              # bind L2VNI to L3VNI (vrf1)
ip link set vlan10 addr aa:bb:cc:00:0${leaf}:6e # unique MAC per L2VNI+VTEP combo (or use anycast MAC, see below)
ip addr add 172.16.10.${leaf}/24 dev vlan10     # shared gateway IP per L2VNI, on all VTEPs
ip link set vlan10 up
###############
## l2vni 120 ##
###############
bridge vlan add dev br0 vid 20 self
bridge vlan add dev vxlan0 vid 20
bridge vni add dev vxlan0 vni 10021
bridge vlan add dev vxlan0 vid 20 tunnel_info id 10021
ip link add vlan20 link br0 type vlan id 20
ip link set vlan20 master vrf10001              # bind L2VNI to L3VNI (vrf1)
ip link set vlan20 addr aa:bb:cc:00:0${leaf}:6e # unique MAC per L2VNI+VTEP combo (or use anycast MAC, see below)
ip addr add 172.16.20.${leaf}/24 dev vlan20     # shared gateway IP per L2VNI, on all VTEPs
ip link set vlan20 up
