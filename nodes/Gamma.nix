{
  nodes.Gamma = {
    meta.system = "x86_64-linux";

    traits = [
      "base"
      "font"
      "desktop"
      "fcitx5"
      "software"
      "game"
      "hack"
      "proxy"
      "virtualisation"
      "disko"
      "lanzaboote"
      "nixvim"
      "preservation"
      "unfree"
    ];

    schema = {
      base = {
        hostName = "Gamma";
        userName = "saya";
        password = "none";
        bootLoaderTimeout = 2;
      };
      font.extra = true;
      software.extra = true;
      disko = {
        swapfileSize = "16G";
      };
    };

    includes = [
      ../platform/inspiron-5577.nix
      ../resource/resource.nix
    ];
  };
}
