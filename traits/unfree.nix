{
  traits = [
    {
      name = "unfree";
      module =
        { conf, ... }:
        { lib, pkgs, ... }:
        {
          nixpkgs.config.allowUnfreePredicate =
            pkg:
            builtins.elem (lib.getName pkg) [
              "crossover"
              "ida-pro"
              "nvidia-settings"
              "nvidia-x11"
              "steam"
              "steam-unwrapped"
            ];

          # nixpkgs.config.cudaSupport = true;

          environment.systemPackages = with pkgs; [
            (callPackage ./_pkgs/crossover.nix { })
            # (callPackage ./_pkgs/ida-pro.nix {})
          ];

          programs.steam = {
            enable = true;
            gamescopeSession.enable = true;
            extest.enable = true;
            remotePlay.openFirewall = true;
            dedicatedServer.openFirewall = true;
            localNetworkGameTransfers.openFirewall = true;
          };
        };
    }
  ];
}
