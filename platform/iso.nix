{
  conf,
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
  services.greetd.settings.default_session.command = lib.mkForce ''
    ${lib.getExe pkgs.tuigreet} -g "The username is '${conf.base.userName}' or 'root'."
  '';
}
