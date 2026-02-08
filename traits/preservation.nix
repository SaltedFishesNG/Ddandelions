{ inputs, ... }:
{
  traits = [
    {
      name = "preservation";
      module =
        { conf, ... }:
        {
          imports = [ inputs.preservation.nixosModules.preservation ];

          preservation.enable = true;
          preservation.preserveAt."/persist" = {
            files = [ ];
            directories = [
              "/etc/v2raya"
              "/var/lib/archisteamfarm/config"
              "/var/lib/bluetooth"
              "/var/lib/flatpak"
              "/var/lib/iwd"
              "/var/lib/libvirt"
            ];
          };
          preservation.preserveAt."/persist".users.${conf.base.userName} = {
            files = [ ".local/share/fish/fish_history" ];
            directories = [
              "Documents"
              "Downloads"
              "Music"
              "Pictures"
              "Projects"

              {
                directory = ".gnupg";
                mode = "0700";
              }
              {
                directory = ".ssh";
                mode = "0700";
              }
              ".config/qBittorrent"
              ".local/share/qBittorrent"
              ".mozilla/firefox/default"
              ".thunderbird/default"
              ".var/app" # flatpak

              # Game
              ".local/share/PrismLauncher"
              ".local/share/Steam"
              ".steam"
            ];
          };
        };
    }
  ];
}
