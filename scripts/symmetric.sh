##############################
leaf=4

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
## ip-vrf vrf10001 / l3vni 10001 ##
#############################
# Choose any arbitrary VLAN for L3VNIs, since it never leaves the device
# as long as it doesn't collide with another VLAN. It's used solely to
# bind into a routing table (VRF)
bridge vlan add dev br0 vid 1001 self
bridge vlan add dev vxlan0 vid 1001
bridge vni add dev vxlan0 vni 10001                                   # add vni if using vnifilter
bridge vlan add dev vxlan0 vid 1001 tunnel_info id 10001              # map vlan to vni
ip link add vni10001 link br0 type vlan id 1001                       # create vlan on top of bridge
ip link set vni10001 address b2:4b:95:b6:a4:f${leaf} addrgenmode none # set L3VNI devices to routermac and no address
ip link set vni10001 master vrf10001                                  # bind the device to the correct VRF, no address for L3VNI
ip link set vni10001 up

###############
## l2vni 110 ##
###############
bridge vlan add dev br0 vid 10 self
bridge vlan add dev vxlan0 vid 10
bridge vni add dev vxlan0 vni 10011
bridge vlan add dev vxlan0 vid 10 tunnel_info id 10011
ip link add tn1-vlan10 link br0 type vlan id 10
ip link set tn1-vlan10 master vrf10001 # bind L2VNI to L3VNI (vrf1)
# ip link set tn1-vlan10 addr aa:bb:cc:00:0${leaf}:6e # unique MAC per L2VNI+VTEP combo (or use anycast MAC, see below)
ip addr add 172.16.10.1${leaf}/24 dev tn1-vlan10 # shared gateway IP per L2VNI, on all VTEPs
ip link set tn1-vlan10 up
###############
# anycast gateway
###############
# Create a macvlan device from L2VNI to serve as anycast gateway
ip link add tn1-vlan10agw link tn1-vlan10 type macvlan mode private
# Example for L2VNI 110 with anycast MAC aa:bb:cc:dd:ee:ff
ip link set tn1-vlan10agw addr aa:bb:cc:dd:ee:10 # same MAC on all VTEPs
ip addr add 172.16.10.1/24 dev tn1-vlan10agw
ip link set tn1-vlan10agw master vrf10001
# Critical: add local FDB entry to prevent anycast MAC from going over overlay
bridge fdb add aa:bb:cc:dd:ee:10 dev br0 self local
ip link set tn1-vlan10agw up

###############
## l2vni 120 ##
###############
if [ "${leaf}" -eq 4 ]; then
  bridge vlan add dev br0 vid 20 self
  bridge vlan add dev vxlan0 vid 20
  bridge vni add dev vxlan0 vni 10021
  bridge vlan add dev vxlan0 vid 20 tunnel_info id 10021
  ip link add tn1-vlan20 link br0 type vlan id 20
  ip link set tn1-vlan20 master vrf10001 # bind L2VNI to L3VNI (vrf1)
  # ip link set tn1-vlan20 addr aa:bb:cc:00:0${leaf}:6e # unique MAC per L2VNI+VTEP combo (or use anycast MAC, see below)
  ip addr add 172.16.20.1${leaf}/24 dev tn1-vlan20 # shared gateway IP per L2VNI, on all VTEPs
  ip link set tn1-vlan20 up
  ###############
  # anycast gateway
  ###############
  # Create a macvlan device from L2VNI to serve as anycast gateway
  ip link add tn1-vlan20agw link tn1-vlan20 type macvlan mode private
  # Example for L2VNI 120 with anycast MAC aa:bb:cc:dd:ee:ff
  ip link set tn1-vlan20agw addr aa:bb:cc:dd:ee:20 # same MAC on all VTEPs
  ip link set tn1-vlan20agw master vrf10001
  ip addr add 172.16.20.1/24 dev tn1-vlan20agw
  # Critical: add local FDB entry to prevent anycast MAC from going over overlay
  bridge fdb add aa:bb:cc:dd:ee:20 dev br0 self local
  ip link set tn1-vlan20agw up
fi

#############################
# vxlan1
#############################
ip link add br1 type bridge vlan_filtering 1 vlan_default_pvid 0
# the key setting for SVD configuration is "external"
# "vnifilter" isn't strictly necessary but is correct
ip link add vxlan1 type vxlan dstport 4789 local 10.1.254.${leaf} nolearning external vnifilter
ip link set br1 addrgenmode none
ip link set vxlan1 addrgenmode none master br1
ip link set br1 address b2:4b:95:b6:a5:f${leaf}
ip link set vxlan1 address b2:4b:95:b6:a5:f${leaf}
ip link set br1 up
ip link set vxlan1 up
bridge link set dev vxlan1 vlan_tunnel on neigh_suppress on learning off

#############################
## ip-vrf vrf10002 / l3vni 10002 ##
#############################
ip link add vrf10002 type vrf table 10002
ip link set vrf10002 up
# Choose any arbitrary VLAN for L3VNIs, since it never leaves the device
# as long as it doesn't collide with another VLAN. It's used solely to
# bind into a routing table (VRF)
bridge vlan add dev br1 vid 1002 self
bridge vlan add dev vxlan1 vid 1002
bridge vni add dev vxlan1 vni 10002                                   # add vni if using vnifilter
bridge vlan add dev vxlan1 vid 1002 tunnel_info id 10002              # map vlan to vni
ip link add vni10002 link br1 type vlan id 1002                       # create vlan on top of bridge
ip link set vni10002 address b2:4b:95:b6:a5:f${leaf} addrgenmode none # set L3VNI devices to routermac and no address
ip link set vni10002 master vrf10002                                  # bind the device to the correct VRF, no address for L3VNI
ip link set vni10002 up

###############
## l2vni 110 ##
###############
bridge vlan add dev br1 vid 10 self
bridge vlan add dev vxlan1 vid 10
bridge vni add dev vxlan1 vni 10012
bridge vlan add dev vxlan1 vid 10 tunnel_info id 10012
ip link add tn2-vlan10 link br1 type vlan id 10
ip link set tn2-vlan10 master vrf10002 # bind L2VNI to L3VNI (vrf1)
# ip link set tn2-vlan10 addr aa:bb:cc:00:2${leaf}:6e # unique MAC per L2VNI+VTEP combo (or use anycast MAC, see below)
ip addr add 172.17.10.1${leaf}/24 dev tn2-vlan10 # shared gateway IP per L2VNI, on all VTEPs
ip link set tn2-vlan10 up
###############
# anycast gateway
###############
# Create a macvlan device from L2VNI to serve as anycast gateway
ip link add tn2-vlan10agw link tn2-vlan10 type macvlan mode private
# Example for L2VNI 110 with anycast MAC aa:bb:cc:dd:ee:ff
ip link set tn2-vlan10agw addr aa:bb:cc:dd:ff:10 # same MAC on all VTEPs
ip link set tn2-vlan10agw master vrf10002
ip addr add 172.17.10.1/24 dev tn2-vlan10agw
# Critical: add local FDB entry to prevent anycast MAC from going over overlay
bridge fdb add aa:bb:cc:dd:ff:10 dev br0 self local
ip link set tn2-vlan10agw up

if [ "${leaf}" -eq 4 ]; then
  ###############
  ## l2vni 130 ##
  ###############
  bridge vlan add dev br1 vid 30 self
  bridge vlan add dev vxlan1 vid 30
  bridge vni add dev vxlan1 vni 10022
  bridge vlan add dev vxlan1 vid 30 tunnel_info id 10022
  ip link add tn2-vlan30 link br1 type vlan id 30
  ip link set tn2-vlan30 master vrf10002 # bind L2VNI to L3VNI (vrf1)
  # ip link set tn2-vlan30 addr aa:bb:cc:00:2${leaf}:6e # unique MAC per L2VNI+VTEP combo (or use anycast MAC, see below)
  ip addr add 172.17.30.1${leaf}/24 dev tn2-vlan30 # shared gateway IP per L2VNI, on all VTEPs
  ip link set tn2-vlan30 up
  ###############
  # anycast gateway
  ###############
  # Create a macvlan device from L2VNI to serve as anycast gateway
  ip link add tn2-vlan30agw link tn2-vlan30 type macvlan mode private
  # Example for L2VNI 110 with anycast MAC aa:bb:cc:dd:ee:ff
  ip link set tn2-vlan30agw addr aa:bb:cc:dd:ff:30 # same MAC on all VTEPs
  ip link set tn2-vlan30agw master vrf10002
  ip addr add 172.17.30.1/24 dev tn2-vlan30agw
  # Critical: add local FDB entry to prevent anycast MAC from going over overlay
  bridge fdb add aa:bb:cc:dd:ff:30 dev br0 self local
  ip link set tn2-vlan30agw up
fi
