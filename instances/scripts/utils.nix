{
  formats,
}:
let
  jsonFormat = formats.json { };
in
{
  caConfig = jsonFormat.generate "ca-config.json" {
    signing = {
      default.expiry = "87600h";
      profiles = {
        intermediate_ca = {
          expiry = "43800h";
          usages = [
            "cert sign"
            "crl sign"
          ];
          ca_constraint = {
            is_ca = true;
            max_path_len = 0;
            max_path_len_zero = true;
          };
        };
        client = {
          expiry = "8760h";
          usages = [
            "signing"
            "key encipherment"
            "client auth"
          ];
        };
        peer = {
          "expiry" = "8760h";
          "usages" = [
            "signing"
            "key encipherment"
            "client auth"
            "server auth"
          ];
        };
        server = {
          "expiry" = "8760h";
          "usages" = [
            "signing"
            "key encipherment"
            "server auth"
          ];
        };
        both = {
          "expiry" = "8760h";
          "usages" = [
            "signing"
            "key encipherment"
            "client auth"
            "server auth"
          ];
        };
      };
    };
  };
  mkCsr =
    {
      O,
      CN,
      hosts ? [ ],
    }:
    jsonFormat.generate "ca-csr.json" {
      inherit CN hosts;
      key = {
        algo = "rsa";
        size = 2048;
      };
      names = [
        {
          C = "Japan";
          ST = "Asia";
          L = "Tokyo";
          inherit O;
        }
      ];
    };
}
