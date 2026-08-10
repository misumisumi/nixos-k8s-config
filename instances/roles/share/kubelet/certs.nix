{
  pkgs,
  secretPath,
  tag,
  ...
}:
{
  systemd.services."copy-kubelet-certs" = {
    requiredBy = [ "kubelet.service" ];
    before = [ "kubelet.service" ];
    script = ''
      ${pkgs.rsync}/bin/rsync --chmod=644 /etc/kubernetes/pki/${tag}/$(${pkgs.hostname}/bin/hostname)-chain.pem /etc/kubernetes/pki/kubelet.pem
      ${pkgs.rsync}/bin/rsync --chmod=600 /etc/kubernetes/pki/${tag}/$(${pkgs.hostname}/bin/hostname)-key.pem /etc/kubernetes/pki/kubelet-key.pem
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
      source = secretPath + "/pki/kubernetes/${tag}";
      target = "/etc/kubernetes/pki/${tag}";
      user = "root";
      group = "root";
      mode = "0700";
    }
  ];
}
