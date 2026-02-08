{
  traits = [
    {
      name = "game";
      module =
        { conf, ... }:
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            prismlauncher
            protonplus
          ];

          programs = {
            gamescope = {
              enable = true;
              env = {
                __VK_LAYER_NV_optimus = "NVIDIA_only";
                __GLX_VENDOR_LIBRARY_NAME = "nvidia";
              };
            };
            gamemode = {
              enable = true;
              settings = {
                general = {
                  renice = 10;
                };
                gpu = {
                  apply_gpu_optimisations = "accept-responsibility";
                  gpu_device = 0;
                  amd_performance_level = "high";
                  nv_powermizer_mode = 1;
                };
              };
              enableRenice = true;
            };
          };

          services.archisteamfarm = {
            enable = false;
            web-ui.enable = true;
          };

          users.users.${conf.base.userName}.extraGroups = [ "gamemode" ];
        };
    }
  ];
}
