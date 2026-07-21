{
  secretPath,
  ...
}:
{
  system.build.extraContents = [
    {
      source = secretPath + "/pki/RootCA/ca.pem";
      target = "/etc/kubernetes/pki/etcd/ca.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/etcd/server-chain.pem";
      target = "/etc/kubernetes/pki/etcd/server.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/etcd/server-key.pem";
      target = "/etc/kubernetes/pki/etcd/server-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/etcd/peer-chain.pem";
      target = "/etc/kubernetes/pki/etcd/peer.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/etcd/peer-key.pem";
      target = "/etc/kubernetes/pki/etcd/peer-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
  ];
}
