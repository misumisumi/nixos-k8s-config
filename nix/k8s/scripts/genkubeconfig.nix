{
  lib,
  writeShellScriptBin,
  jq,
  envsubst,
  ...
}:
let
  inherit (builtins) getEnv toJSON pathExists;
  inherit (lib)
    concatStringsSep
    importTOML
    mapAttrsToList
    ;

  variants = {
    production = (importTOML ../roles/static.toml).k8s.settings;
    develop = (importTOML ../roles/static_dev.toml).k8s.settings;
    test = (importTOML ../roles/static_dev.toml).k8s.settings;
  };
  kubeconfig =
    variant: serverIP: extraConf:
    {
      apiVersion = "v1";
      kind = "Config";
      current-context = variant;
      clusters = [
        {
          name = variant;
          cluster = {
            certificate-authority = "$PROJ_ROOT/nix/k8s/secrets/${variant}/pki/RootCA/ca.pem";
            server = "https://${serverIP}";
          };
        }
      ];
      contexts = [
        {
          name = variant;
          context = {
            cluster = variant;
            user = "user";
          };
        }
      ];
      users = [
        {
          name = "user";
          user = {
            client-certificate = "$PROJ_ROOT/nix/k8s/secrets/${variant}/pki/kubernetes/admin-chain.pem";
            client-key = "$PROJ_ROOT/nix/k8s/secrets/${variant}/pki/kubernetes/admin-key.pem";
          };
        }
      ];
    }
    // extraConf;
in
# ${pkgs.envsubst}/bin/envsubst -i "${keepalivedConf}" > ${finalConfigFile}
writeShellScriptBin "genkubeconfig" ''
  PROJ_ROOT=''${FLAKE_ROOT:-$PWD}
  echo "Output kubeconfigs under $PROJ_ROOT"

  ${concatStringsSep "\n" (
    mapAttrsToList (k: v: ''
      OUTFILE="$PROJ_ROOT/nix/k8s/secrets/${k}/kubeconfig"
      [ -f "$OUTFILE" ] && rm "$OUTFILE"
      mkdir -p "$(dirname $OUTFILE)"
      tmpFile=$(mktemp)
      ${jq}/bin/jq <<EOF > "$tmpFile"
      ${toJSON (kubeconfig k v.apiserverAddress (v.extraKubeConfig or { }))}
      EOF
      ${envsubst}/bin/envsubst -i "$tmpFile" > "$OUTFILE"
    '') variants
  )}
''
