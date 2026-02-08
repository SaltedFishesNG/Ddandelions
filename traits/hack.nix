{
  traits = [
    {
      name = "hack";
      module =
        { conf, ... }:
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            # aircrack-ng
            # (cutter.withPlugins (ps: with ps; [jsdec rz-ghidra sigdb]))
            # ghidra-bin
            # nikto
            nmap
            # nuclei
            (proxmark3.override { hardwarePlatform = "PM3GENERIC"; })
            wireshark
          ];

          programs.wireshark = {
            enable = true;
            usbmon.enable = true;
            dumpcap.enable = true;
          };

          users.users.${conf.base.userName}.extraGroups = [ "wireshark" ];
        };
    }
  ];
}
