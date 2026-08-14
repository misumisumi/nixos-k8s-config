{
  lib,
  writeText,
  static,
}:
let
  manageIP = lib.removeNetmask static.switch.sks8300-8x.networks.manage.address;
in
writeText "dropbear" ''
  config dropbear main
      option enable '1'
      option PasswordAuth 'no'
      option RootPasswordAuth 'no'
      option Port         '22'
      option PermitOpen '${manageIP}:22'
''
