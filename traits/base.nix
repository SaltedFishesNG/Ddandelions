{
  mkBool,
  mkInt,
  mkStr,
  ...
}:
{
  schema.base = {
    hostName = mkStr null;
    userName = mkStr null;
    password = mkStr null;
    hashedPassword = mkStr null;
    useSudo-rs = mkBool false;
    bootLoaderTimeout = mkInt null;
    useWireless = mkBool true;
    useNetworkManager = mkBool true;
    useTPM2 = mkBool true;
    useBluetooth = mkBool true;
    useSleep = mkBool true;
    useAudio = mkBool true;
  };

  traits = [
    {
      name = "base";
      module =
        { conf, ... }:
        { lib, pkgs, ... }:
        let
          cfg = conf.base;
        in
        {
          time.timeZone = "UTC";
          i18n.defaultLocale = "C.UTF-8";
          console.keyMap = "us";

          boot = {
            kernelPackages = pkgs.linuxPackages_latest;
            tmp.cleanOnBoot = true;
            initrd.systemd.enable = true;
            loader.systemd-boot.enable = lib.mkDefault true;
            loader.systemd-boot.configurationLimit = 25;
            loader.efi.canTouchEfiVariables = true;
          }
          // lib.optionalAttrs (cfg.bootLoaderTimeout != null) {
            loader.timeout = cfg.bootLoaderTimeout;
          };
          system.nixos-init.enable = true;
          system.etc.overlay.enable = true;

          networking = {
            hostName = lib.mkDefault cfg.hostName;
            nftables.enable = true;
            dhcpcd.enable = false;
            resolvconf.enable = false;
            networkmanager.enable = cfg.useNetworkManager;
            networkmanager.wifi.backend = lib.mkIf cfg.useWireless "iwd";
            wireless.iwd.enable = cfg.useWireless;
            useNetworkd = !cfg.useNetworkManager;
            useDHCP = !cfg.useNetworkManager;
          };
          systemd.network.enable = !cfg.useNetworkManager;
          services.resolved.enable = false;
          environment.etc."resolv.conf".text = ''
            nameserver 1.1.1.1
            nameserver 2606:4700:4700::1111
            nameserver 8.8.8.8
            nameserver 2001:4860:4860::8888
          '';

          users.mutableUsers = false;
          users.users.${cfg.userName} = {
            password = cfg.password;
            hashedPassword = cfg.hashedPassword;
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObSiBahejD/fe1MOfbrW1XF29t/4yRAPcwphHEFVqET main@saltedfishes.com"
            ];
            isNormalUser = true;
            extraGroups = [
              "audio"
              "video"
              "wheel"
            ];
            shell = pkgs.fish;
          };
          programs.fish = {
            enable = true;
            shellInit = "set fish_color_command blue";
          };

          security = {
            doas = {
              enable = true;
              extraConfig = "permit persist keepenv :wheel";
            };
            rtkit.enable = true;
            sudo.enable = false;
            sudo-rs = lib.mkIf cfg.useSudo-rs {
              enable = true;
              execWheelOnly = true;
              wheelNeedsPassword = false;
            };
            tpm2 = lib.mkIf cfg.useTPM2 {
              enable = true;
              pkcs11.enable = true;
              tctiEnvironment.enable = true;
            };
          };

          hardware.bluetooth = lib.mkIf cfg.useBluetooth {
            enable = true;
            powerOnBoot = true;
            settings.General.Experimental = true;
          };

          systemd.enableEmergencyMode = false;
          systemd.sleep.extraConfig = lib.mkIf cfg.useSleep ''
            HibernateDelaySec=30min
            HibernateMode=shutdown platform
          '';
          services = {
            logind.settings.Login = lib.mkIf cfg.useSleep {
              HandlePowerKey = "hibernate";
              HandleLidSwitch = "suspend-then-hibernate";
            };
            openssh = {
              enable = true;
              ports = [ 22 ];
              settings = {
                PasswordAuthentication = false;
                PermitRootLogin = lib.mkForce "prohibit-password";
              };
            };
            kmscon = {
              enable = true;
              extraOptions = "--term xterm-256color";
            };
            zram-generator = {
              enable = true;
              settings.zram0 = {
                compression-algorithm = "zstd";
                zram-size = "ram";
              };
            };
            userborn.enable = true;
            dbus.implementation = "broker";
            pulseaudio.enable = false;
            pipewire = lib.mkIf cfg.useAudio {
              enable = true;
              alsa.enable = true;
              pulse.enable = true;
            };
          };

          documentation.nixos.enable = false;
          documentation.man.generateCaches = false; # Slow build due to fish enabling generateCaches

          nix = {
            package = pkgs.nixVersions.latest;
            channel.enable = false;
            settings = {
              substituters = [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
              trusted-users = [ "${cfg.userName}" ];
              experimental-features = [
                "auto-allocate-uids"
                "ca-derivations"
                "cgroups"
                "flakes"
                "nix-command"
                "no-url-literals"
                "pipe-operators"
              ];
              auto-allocate-uids = true;
              auto-optimise-store = true;
              builders-use-substitutes = true;
              pure-eval = true;
              use-cgroups = true;
            };
            gc = {
              automatic = true;
              dates = "weekly";
              options = "--delete-older-than 7d";
            };
          };

          system.stateVersion = "26.05";
        };
    }
  ];
}
