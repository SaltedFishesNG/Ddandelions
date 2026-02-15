{
  traits.desktop =
    {
      config,
      lib,
      pkgs,
      schema,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        adw-gtk3
        adwaita-icon-theme
        bibata-cursors
        brightnessctl
        file-roller
        firefox
        fuzzel
        mako
        nautilus
        papirus-icon-theme
        pavucontrol
        qgnomeplatform
        qgnomeplatform-qt6
        swaybg
        swayidle
        swaylock
        waybar
        wezterm
        xwayland-satellite
      ];

      programs = {
        dconf.profiles.user.databases = [
          {
            settings."org/gnome/desktop/interface" = {
              cursor-size = lib.gvariant.mkInt32 20;
              cursor-theme = "Bibata-Modern-Ice";
              gtk-theme = "adw-gtk3";
              icon-theme = "Papirus";
            };
          }
        ];
        niri.enable = true;
        nm-applet.enable = config.networking.networkmanager.enable;
      };

      systemd.services.greetd.serviceConfig = {
        Type = lib.mkForce "simple";
        ExecStartPre = [ "-${pkgs.coreutils}/bin/kill -SIGRTMIN+21 1" ];
        ExecStopPost = [ "-${pkgs.coreutils}/bin/kill -SIGRTMIN+20 1" ];
      };
      services = {
        blueman.enable = config.hardware.bluetooth.enable;
        greetd = {
          enable = true;
          settings.default_session = {
            command = "${lib.getExe pkgs.tuigreet}";
            user = "${schema.base.userName}";
          };
          useTextGreeter = true;
        };
        gvfs.enable = true;
        playerctld.enable = config.services.pipewire.enable;

        xserver = {
          enable = true;
          displayManager.startx.enable = true;
          windowManager.i3.enable = true;
        };
      };

      environment.sessionVariables = {
        DEFAULT_BROWSER = "${lib.getExe pkgs.firefox}";
      };

      xdg.mime.defaultApplications = {
        "image/*" = "firefox.desktop";
        "application/pdf" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
}
