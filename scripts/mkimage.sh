#!/usr/bin/env bash

# line="bgp.ix2215"
# image="mylab/${line#bgp.}"
# incus image delete "${image}"
# incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"

# line="bgp.ibl2"
# image="mylab/${line#bgp.}"
# incus image delete "${image}"
# incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"

# while read -r line; do
#   image="mylab/${line#bgp.}"
#   incus image delete "${image}"
#   incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"
# done < <(nix flake show | grep "bgp.spine" | sed -n 's/.*"\([^"]*\)".*/\1/p')

# count=0
# while read -r line; do
#   image="mylab/${line#bgp.}"
#   incus image delete "${image}"
#   incus image import "$(nixos-generate -f lxc-metadata)" "$(nixos-generate -f qcow --flake ".#${line}")" --alias "${image}"
#   count=$((count + 1))
#   [[ "${count}" -eq 2 ]] && break
# done < <(nix flake show | grep "bgp.leaf" | sed -n 's/.*"\([^"]*\)".*/\1/p')

# image="test_mngr_admiral"
# incus image import "$(nixos-rebuild build-image --flake ".#${image}" --image-variant lxc-metadata)" "$(nixos-rebuild build-image --flake ".#${image}" --image-variant lxc)" --alias "${image//_//}"

image="test_mngr_image-server"
incus image import "$(nixos-rebuild build-image --flake ".#${image}" --image-variant lxc-metadata)" "$(nixos-rebuild build-image --flake ".#${image}" --image-variant lxc)" --alias "${image//_//}"
