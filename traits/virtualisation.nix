{ mkBool, ... }:
{
  schema.virtualisation = {
    useLibvirt = mkBool false;
    useXen = mkBool false;
    useLxc = mkBool false;
  };

  traits.virtualisation =
    {
      lib,
      pkgs,
      schema,
      ...
    }:
    let
      cfg = schema.virtualisation;
      userName = schema.base.userName;
    in
    {
      virtualisation = {
        libvirtd = {
          enable = cfg.useLibvirt;
          qemu = {
            swtpm.enable = true;
            vhostUserPackages = [ pkgs.virtiofsd ];
          };
          onShutdown = "shutdown";
        };
        xen = {
          enable = cfg.useXen;
          dom0Resources.memory = 10000;
        };
        lxc.enable = cfg.useLxc;
      };

      environment.systemPackages = with pkgs; [
        qemu
        virglrenderer
        virt-manager
        virt-viewer
        virtiofsd
      ];

      programs.dconf.profiles.user.databases =
        let
          uris = [
            "qemu:///session"
          ]
          ++ lib.optionals cfg.useLibvirt [ "qemu:///system" ]
          ++ lib.optionals cfg.useXen [ "xen:///" ]
          ++ lib.optionals (cfg.useLxc && cfg.useLibvirt) [ "lxc:///" ];
        in
        [
          {
            settings."org/virt-manager/virt-manager/connections".autoconnect = uris;
            settings."org/virt-manager/virt-manager/connections".uris = uris;
          }
        ];

      users.users.${userName}.extraGroups = [ "kvm" ] ++ lib.optionals cfg.useLibvirt [ "libvirtd" ];
      networking.firewall.trustedInterfaces = lib.mkIf cfg.useLibvirt [ "virbr0" ];
    };
}
