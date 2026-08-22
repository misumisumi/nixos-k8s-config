{
  inputs,
  lib,
  hostSecretPath,
  modulesPath,
  ...
}:
{
  imports = [
    ../../../share/apps/debug.nix
    inputs.homelab-modules.nixosModules.incus-vm
  ];

  # dev は incus VM イメージとしてビルド（mkimg.incus-vm dev_cloud_oci）
  image.modules = lib.mkForce {
    incus-vm = inputs.homelab-modules.nixosModules.incus-vm;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };

  # dev 用に事前生成した ssh ホスト鍵をイメージへ焼き込み。
  # sops.age.generateKey がこの ssh 鍵から keys.txt（age 鍵）を導出して復号する。
  system.build.extraContents = [
    {
      source = hostSecretPath + "/ssh/ssh_host_ed25519_key";
      target = "/etc/ssh/ssh_host_ed25519_key";
      mode = "0600";
    }
    {
      source = hostSecretPath + "/ssh/ssh_host_ed25519_key.pub";
      target = "/etc/ssh/ssh_host_ed25519_key.pub";
      mode = "0644";
    }
  ];
}