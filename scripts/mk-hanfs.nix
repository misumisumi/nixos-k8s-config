{writeShellApplication}:
writeShellApplication {
  name = "mk-hanfs";
  text = ''

    TARGETS=$1
    colmena exec --on @nfs1 "pcs cluster auth ''${TARGETS}"
    colmena exec --on @nfs1 "pcs cluster setup --name nfs_cluster ''${TARGETS}"
    colmena exec --on @nfs1 "pcs cluster start --all"
    colmena exec --on @nfs1 "pcs property set stonith-enabled=false"
    colmena exec --on @nfs1 "pcs property set no-quorum-policy='ignore'"
    colmena exec --on @nfs1 "pcs -f drbdcluster resource create VirtualIP ocf:heartbeat:IPaddr2 \
                            ip="''$(jq -r .values.outputs.cluster_info.value.etcd.etcd1 show.json | awk -F'.' '{ print $1"."$2"."$3"." }')".70 \
                            cidr_netmask='24' nic='eth0' \
                            op monitor interval='10s'"
  '';
}