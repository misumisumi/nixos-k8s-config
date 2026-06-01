{ pkgs, secretPath, ... }:
{
  systemd.services."copy-kubelet-certs" = {
    requiredBy = [ "kubelet.service" ];
    before = [ "kubelet.service" ];
    script = ''
      rsync --chmod=0644 /etc/kubernetes/pki/workers/$(${pkgs.hostname}/bin/hostname)-chain.pem /etc/kubernetes/pki/kubelet.pem
      rsync --chmod=0600 /etc/kubernetes/pki/workers/$(${pkgs.hostname}/bin/hostname)-key.pem /etc/kubernetes/pki/kubelet-key.pem
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
      source = secretPath + "/pki/kubernetes/workers";
      target = "/etc/kubernetes/pki/workers";
      user = "root";
      group = "root";
      mode = "0700";
    }
  ];
}
