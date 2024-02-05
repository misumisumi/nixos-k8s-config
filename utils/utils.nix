{ lib, ... }:
{
  nodeIPFromTF = r: r.values.ipv4_address;
  getByRole = role: nodes: lib.filterAttrs (x: y: lib.hasPrefix role x) nodes;
}
