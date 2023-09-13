{ lib, ... }:
{
  nodeIPFromTF = r: r.values.ip_address;
  getByRole = role: nodes: lib.filterAttrs (x: y: lib.hasPrefix role x) nodes;
}
