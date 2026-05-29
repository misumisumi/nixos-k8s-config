{
  lib,
  writeShellScriptBin,
  jq,
  ...
}:
let
  inherit (builtins) toJSON pathExists;
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
    let
      rootCA =
        if pathExists ../secrets/${variant}/pki/RootCA/ca.pem then
          ../secrets/${variant}/pki/RootCA/ca.pem
        else
          "";
      clientCert =
        if pathExists ../secrets/${variant}/pki/kubernetes/admin-chain.pem then
          ../secrets/${variant}/pki/kubernetes/admin-chain.pem
        else
          "";
      clientKey =
        if pathExists ../secrets/${variant}/pki/kubernetes/admin-key.pem then
          ../secrets/${variant}/pki/kubernetes/admin-key.pem
        else
          "";
    in
    {
      apiVersion = "v1";
      kind = "Config";
      current-context = variant;
      clusters = [
        {
          name = variant;
          cluster = {
            certificate-authority = rootCA;
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
            client-certificate = clientCert;
            client-key = clientKey;
          };
        }
      ];
    }
    // extraConf;
in
writeShellScriptBin "genkubeconfig" ''
  ROOTDIR=''${FLAKE_ROOT:-$PWD}
  ${concatStringsSep "\n" (
    mapAttrsToList (k: v: ''
      OUTFILE="$ROOTDIR/nix/k8s/secrets/${k}/kubeconfig"
      [ -f "$OUTFILE" ] && rm "$OUTFILE"
      mkdir -p "$(dirname $OUTFILE)"
      ${jq}/bin/jq <<EOF > "$OUTFILE"
      ${toJSON (kubeconfig k v.apiserverAddress (v.extraKubeConfig or { }))}
      EOF
    '') variants
  )}
''
