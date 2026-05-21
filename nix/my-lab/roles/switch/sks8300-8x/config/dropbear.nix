{
  writeText,
  static,
}:
let
  inherit (static.switch.sks8300-8x)
    manageIP
    ;
in
writeText "dropbear" ''
  config dropbear main
      option enable '1'
      option PasswordAuth 'no'
      option RootPasswordAuth 'no'
      option Port         '22'
      option PermitOpen '${manageIP}:22'
''
