{ pkgs, openwrt-imagebuilder, ... }:
let
  inherit (pkgs.lib) optionalString;

  release = "25.12.4";
  profiles = openwrt-imagebuilder.lib.profiles {
    inherit pkgs release;
  };

  config =
    {
      isDev ? false,
    }:
    {
      disabledServices = [ "dnsmasq" ];

      # include files in the images.
      # to set UCI configuration, create a uci-defauts scripts as per
      # official OpenWRT ImageBuilder recommendation.
      files = pkgs.runCommand "image-files" { } (
        ''
          mkdir -p $out/etc/uci-defaults
          cp ${./99-custom} $out/etc/uci-defaults/99-custom
        ''
        + optionalString isDev ''
          cp ${./97-incus-agent} $out/etc/uci-defaults/97-incus-agent
          cp ${./98-dev-custom} $out/etc/uci-defaults/98-dev-custom
        ''
      );
    };
  packages = [ "frr" ];
in
{
  # prod_switch_sks8300-8x = profiles.identifyProfile "realtek_rtl930x" // config;
  prod_switch_sks8300-8x = openwrt-imagebuilder.lib.build (
    profiles.identifyProfile "xikestor_sks8300-8x"
    // config { isDev = false; }
    // {
      inherit packages;
    }
  );
  dev_switch_sks8300-8x =
    (openwrt-imagebuilder.lib.build (
      {
        inherit pkgs;
        target = "x86";
        variant = "64";
        profile = "generic";
        packages = packages ++ [
          # for incus
          "kmod-9pvirtio"
          "kmod-fs-9p"
          "kmod-vsock-virtio"
          "virtio-console-helper"
          # for debugging
          "tcpdump"
        ];
        passthru = {
          lxc-medadata = "openwrt-lxc-metadata-${release}-x86_64-linux.tar.xz";
          qcow2 = "openwrt-${release}-x86-64-generic-squashfs-combined-efi.qcow2";
        };
      }
      // config { isDev = true; }
    )).overrideAttrs
      (old: {
        postInstall = old.postInstall + ''
          ${pkgs.gzip}/bin/gunzip -k $out/openwrt-${release}-x86-64-generic-squashfs-combined-efi.img.gz
          ${pkgs.qemu}/bin/qemu-img convert -f raw -O qcow2 $out/openwrt-${release}-x86-64-generic-squashfs-combined-efi.img $out/openwrt-${release}-x86-64-generic-squashfs-combined-efi.qcow2
          pushd $out
          echo '{"architecture":"x86_64","creation_date":1,"properties":{"description":"Openwrt lxc-metadata-${release} x86_64-linux","os":"openwrt","release":"${release}"},"templates":{}}' > metadata.yaml
          ${pkgs.gnutar}/bin/tar -czvf openwrt-lxc-metadata-${release}-x86_64-linux.tar.xz metadata.yaml
          rm -f metadata.json
          popd
        '';
      });
}
