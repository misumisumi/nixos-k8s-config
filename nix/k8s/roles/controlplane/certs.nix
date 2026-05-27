{ secretPath, ... }:
{
  system.build.extraContents = [
    {
      source = secretPath + "/pki/kubernetes/apiserver-chain.pem";
      target = "/etc/kubernetes/pki/apiserver.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/apiserver-key.pem";
      target = "/etc/kubernetes/pki/apiserver-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/apiserver-kubelet-client-chain.pem";
      target = "/etc/kubernetes/pki/apiserver-kubelet-client.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/apiserver-kubelet-client-key.pem";
      target = "/etc/kubernetes/pki/apiserver-kubelet-client-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/controller-manager-chain.pem";
      target = "/etc/kubernetes/pki/controller-manager-chain.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/controller-manager-key.pem";
      target = "/etc/kubernetes/pki/controller-manager-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/coredns-chain.pem";
      target = "/etc/kubernetes/pki/coredns.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/coredns-key.pem";
      target = "/etc/kubernetes/pki/coredns-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/kubelet-chain.pem";
      target = "/etc/kubernetes/pki/kubelet.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/kubelet-key.pem";
      target = "/etc/kubernetes/pki/kubelet-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/scheduler-chain.pem";
      target = "/etc/kubernetes/pki/scheduler.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/scheduler-key.pem";
      target = "/etc/kubernetes/pki/scheduler-key.pem";
      user = "root";
      group = "root";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/sa.pem";
      target = "/etc/kubernetes/pki/sa.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/sa.key";
      target = "/etc/kubernetes/pki/sa.key";
      user = "root";
      group = "root";
      mode = "0600";
    }
  ];
}
