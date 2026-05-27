{
  callPackage,
  writeShellScriptBin,
}:
{
  mkenv = callPackage ./mkenv.nix { };
  mksshhostkeys = callPackage ./mksshhostkeys.nix { };
  ter = callPackage ./ter.nix { };
  check-disk-size = writeShellScriptBin "check-disk-size" ''
    lsblk -b -io KNAME,TYPE,SIZE,MODEL | awk 'BEGIN{OFS="\t"; OFMT="%.1f"; print "KNAME","TYPE","SIZE","MODEL";} $2 == "disk" {if (FNR>1) print $1,$2,int($3/1073741824)"G",$4; else print $0}'
  '';
}
// (callPackage ./setup-lxd.nix { })
// (callPackage ./mkage.nix { })
