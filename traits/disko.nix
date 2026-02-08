{
  inputs,
  mkBool,
  mkStr,
  ...
}:
{
  schema.disko = {
    device = mkStr "/dev/sda";
    withLUKS = mkBool true;
    swapfileSize = mkStr null;
    espSize = mkStr "1000M";
    withPostMbrGap = mkBool false;
    imageSize = mkStr "2G";
  };

  traits = [
    {
      name = "disko";
      module =
        { conf, ... }:
        { lib, ... }:
        let
          cfg = conf.disko;
          btrfs = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "noatime"
                  "compress-force=zstd"
                ];
              };
              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "noatime"
                  "compress-force=zstd"
                ];
              };
              "/tmp" = {
                mountpoint = "/tmp";
                mountOptions = [
                  "noatime"
                  "compress-force=zstd"
                ];
              };
            }
            // lib.optionalAttrs (cfg.swapfileSize != null) {
              "/swap" = {
                mountpoint = "/swap";
                mountOptions = [ "noatime" ];
                swap.swapfile.size = cfg.swapfileSize;
              };
            };
          };

          luks = {
            type = "luks";
            name = "primary";
            settings = {
              allowDiscards = true;
              bypassWorkqueues = true;
            };
            content = btrfs;
          };
        in
        {
          imports = [ inputs.disko.nixosModules.disko ];

          disko.imageBuilder = {
            enableBinfmt = true;
          };
          disko.devices.nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
              "size=50%"
              "defaults"
              "mode=755"
            ];
          };

          disko.devices.disk.main = {
            imageSize = cfg.imageSize;
            type = "disk";
            device = cfg.device;
            content.type = "gpt";
            content.partitions = {
              ESP = {
                size = cfg.espSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0077"
                    "dmask=0077"
                  ];
                };
              };
              primary = {
                size = "100%";
                content = if cfg.withLUKS then luks else btrfs;
              };
            };
          }
          // lib.optionalAttrs cfg.withPostMbrGap {
            boot = {
              size = "1M";
              type = "EF02";
              priority = 0;
            };
          };
        };
    }
  ];
}
