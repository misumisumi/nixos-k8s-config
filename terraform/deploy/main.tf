module "deploy" {
  for_each = { for i in var.nodes : i.name => i }

  # source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  source                 = "github.com/misumisumi/nixos-anywhere?ref=dd4b761f839175a0927600b8dbf121a17ea1e12a//terraform/all-in-one"
  nixos_system_attr      = ".#nixosConfigurations.${each.value.name}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.value.name}.config.system.build.diskoScript"
  nix_options = {
    pure-eval  = "false"
    eval-cache = "false"
  }
  target_host = each.value.ipv4
  # when instance id changes, it will trigger a reinstall
  instance_id = each.value.ipv4
  # useful if something goes wrong
  debug_logging = true
  # script is below
  extra_environment = {
    HOST_NAME      = each.value.name
    WORKSPACE_NAME = terraform.workspace
  }
  extra_files_script    = "${path.module}/decrypt-secrets.sh"
  ignore_systemd_errors = var.ignore_systemd_errors
  switch_cmd            = var.switch_cmd
  disk_encryption_key_scripts = [
    {
      path = "/tmp/rootfs.key"
      # script is below
      script = "${path.module}/decrypt-rootfs-key.sh"
    },
    {
      path   = "/tmp/keystore.key"
      script = "${path.module}/decrypt-keystore-key.sh"
    },
    {
      path   = "/tmp/ceph.key"
      script = "${path.module}/decrypt-ceph-key.sh"
    },
    {
      path   = "/tmp/nfs.key"
      script = "${path.module}/decrypt-nfs-key.sh"
    }
  ]
}
