#!/usr/bin/env bash

line="bgp.ix2215"
image="mylab/${line#bgp.}"
incus image delete "${image}"
incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"

line="bgp.ibl2"
image="mylab/${line#bgp.}"
incus image delete "${image}"
incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"

while read -r line; do
  image="mylab/${line#bgp.}"
  incus image delete "${image}"
  incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"
done < <(nix flake show | grep "bgp.spine" | sed -n 's/.*"\([^"]*\)".*/\1/p')

while read -r line; do
  image="mylab/${line#bgp.}"
  incus image delete "${image}"
  incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"
done < <(nix flake show | grep "bgp.leaf" | sed -n 's/.*"\([^"]*\)".*/\1/p')
