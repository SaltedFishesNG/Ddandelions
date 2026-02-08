{ mkBool, ... }:
{
  schema.software = {
    extra = mkBool true;
  };

  traits = [
    {
      name = "software";
      module =
        { conf, ... }:
        { lib, pkgs, ... }:
        let
          cfg = conf.software;
        in
        {
          environment.systemPackages =
            with pkgs;
            [
              disko
              file
              git
              gnupg
              ncdu
              nh
              nix-output-monitor
              nixfmt-tree
              parted
              sbctl
              tree
              wget
            ]
            ++ lib.optionals cfg.extra [
              # (bottles.override {removeWarningPopup = true;})
              chromium
              # ladybird
              # libreoffice
              mpv
              qbittorrent
              (symlinkJoin {
                name = "signal-desktop";
                paths = [ signal-desktop ];
                buildInputs = [ makeWrapper ];
                postBuild = ''
                  wrapProgram $out/bin/signal-desktop \
                    --set HTTPS_PROXY "socks5://localhost:1024" \
                    --set HTTP_PROXY "socks5://localhost:1024"
                '';
              })
              # tor-browser
              vscodium
              zed-editor

              android-tools
              appimage-run
              dnsutils
              lsof
              p7zip
              qrencode
              rdap
              steam-run-free
              unrar-free
              unzip
              whois
              zip
            ];

          programs = {
            gnupg.agent = {
              enable = true;
              pinentryPackage = pkgs.pinentry-tty;
            };
            git = {
              enable = true;
              config = {
                core.autocrlf = "input";
                core.editor = "vim";
                merge.autoStash = true;
                pull.autoStash = true;
                pull.rebase = true;
                rebase.autoStash = true;
                safe.directory = "*";
              }
              // lib.optionalAttrs cfg.extra {
                commit.gpgSign = true;
                http.proxy = "socks5://localhost:1024";
                https.proxy = "socks5://localhost:1024";
                tag.gpgSign = true;
                user.email = "main@saltedfishes.com";
                user.name = "SaltedFishes";
                user.signingkey = "0F3659EAC9207CE3B0D7C5ABA4CA90D326E9FB7C";
              };
            };
            htop = {
              enable = true;
              settings = {
                color_scheme = 6;
                hide_userland_threads = true;
                highlight_base_name = true;
                highlight_changes = true;
                shadow_other_users = true;
                show_cpu_temperature = true;
                show_program_path = false;
                tree_view = true;
              };
            };
            mtr.enable = cfg.extra;
            thunderbird.enable = cfg.extra;
            vim = {
              enable = true;
              package = pkgs.vim-full;
            };
          };

          services.flatpak.enable = cfg.extra;
        };
    }
  ];
}
