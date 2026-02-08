{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  imports = [
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
  ];

  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  system.nixos-init.enable = lib.mkForce false;
}
