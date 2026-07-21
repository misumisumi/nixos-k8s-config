{ pkgs, secretPath, ... }:
{
  systemd.services."copy-kubelet-certs" = {
    requiredBy = [ "kubelet.service" ];
    before = [ "kubelet.service" ];
    script = ''
      ${pkgs.rsync}/bin/rsync --chmod=644 /etc/kubernetes/pki/controlplanes/$(${pkgs.hostname}/bin/hostname)-chain.pem /etc/kubernetes/pki/kubelet.pem
      ${pkgs.rsync}/bin/rsync --chmod=600 /etc/kubernetes/pki/controlplanes/$(${pkgs.hostname}/bin/hostname)-key.pem /etc/kubernetes/pki/kubelet-key.pem
    '';
  };
  system.build.extraContents = [
    {
      source = secretPath + "/pki/RootCA/ca.pem";
      target = "/etc/kubernetes/pki/ca.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/controlplanes";
      target = "/etc/kubernetes/pki/controlplanes";
      user = "root";
      group = "root";
      mode = "0700";
    }
    {
      source = secretPath + "/pki/kubernetes/apiserver-chain.pem";
      target = "/etc/kubernetes/pki/apiserver.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/apiserver-key.pem";
      target = "/etc/kubernetes/pki/apiserver-key.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/apiserver-kubelet-client-chain.pem";
      target = "/etc/kubernetes/pki/apiserver-kubelet-client.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/apiserver-kubelet-client-key.pem";
      target = "/etc/kubernetes/pki/apiserver-kubelet-client-key.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/etcd/apiserver-etcd-client-chain.pem";
      target = "/etc/kubernetes/pki/apiserver-etcd-client.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/etcd/apiserver-etcd-client-key.pem";
      target = "/etc/kubernetes/pki/apiserver-etcd-client-key.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/RootCA/ca.pem";
      target = "/etc/kubernetes/pki/etcd/ca.pem";
      user = "root";
      group = "root";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/controller-manager-chain.pem";
      target = "/etc/kubernetes/pki/controller-manager.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/controller-manager-key.pem";
      target = "/etc/kubernetes/pki/controller-manager-key.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/scheduler-chain.pem";
      target = "/etc/kubernetes/pki/scheduler.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/scheduler-key.pem";
      target = "/etc/kubernetes/pki/scheduler-key.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0600";
    }
    {
      source = secretPath + "/pki/kubernetes/sa.pem";
      target = "/etc/kubernetes/pki/sa.pem";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0644";
    }
    {
      source = secretPath + "/pki/kubernetes/sa.key";
      target = "/etc/kubernetes/pki/sa.key";
      user = "kubernetes";
      group = "kubernetes";
      mode = "0600";
    }
  ];
}
