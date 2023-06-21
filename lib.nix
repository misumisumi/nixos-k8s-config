# From https://github.com/numtide/flake-utils
{
  mkApp = {
    drv,
    name ? drv.pname or drv.name,
    exePath ? drv.passthru.exePath or "/bin/${name}",
  }: {
    type = "app";
    program = "${drv}${exePath}";
  };
}