# 参考: https://qiita.com/iaoiui/items/fc2ea829498402d4a8e3
{
  callPackage,
  cfssl,
  writeShellApplication,
  writeText,
}: {
  # 各証明書の有効期限は10年
  caConfig = writeText "ca-config.json" ''
    {
      "signing": {
        "profiles": {
          "client": {
            "expiry": "87600h",
            "usages": ["signing", "key encipherment", "client auth"]
          },
          "peer": {
            "expiry": "87600h",
            "usages": ["signing", "key encipherment", "client auth", "server auth"]
          },
          "server": {
            "expiry": "8760h",
            "usages": ["signing", "key encipherment", "client auth", "server auth"]
          }
        }
      }
    }
  '';
  csrDefault = {
    key = {
      algo = "rsa";
      size = 2048;
    };
    names = {
      "C" = "Japan";
      "ST" = "Asia";
      "L" = "Tokyo";
      "O" = "miSumiSumi";
      "OU" = "CardinalSystem";
    };
  };
}