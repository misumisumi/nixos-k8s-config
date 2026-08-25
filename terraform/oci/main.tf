# OCI への NixOS 展開（nixos-anywhere all-in-one モジュール）
# 値（IP・OCID・SSH 鍵）は branch/production.yaml（平文・git 管理外）から読む。
locals {
  # cwd に依存しないよう、收盘 flake を絶対URI化する
  flake = "git+file://${abspath("${path.module}/../..")}"
}

module "deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"

  nixos_system_attr      = "${local.flake}#nixosConfigurations.prod_cloud_oci.config.system.build.toplevel"
  nixos_partitioner_attr = "${local.flake}#nixosConfigurations.prod_cloud_oci.config.system.build.diskoScript"

  target_host = var.target_host

  # インストール時: 動作中の Ubuntu へは ubuntu + OCI コンソール用鍵で接続
  install_user    = var.install_user
  install_ssh_key = var.install_ssh_key

  # 再起動後の更新: root + sumi 鍵で nixos-rebuild を実行
  # （deployment_ssh_key 未設定時は ssh-agent を使用）
  target_user = "root"

  # 再インストールのトリガー
  instance_id = var.instance_id
  phases      = var.phases

  # ssh ホスト鍵を /etc/ssh へ投入（sops.age.generateKey がここから age 鍵を導出）
  extra_files_script = "${path.module}/secrets.sh"
}

output "system" {
  value = module.deploy.result
}
