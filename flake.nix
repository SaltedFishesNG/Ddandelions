{
  description = "Until dandelions spread across the desert...";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nixy.url = "github:anialic/nixy";
    preservation.url = "github:nix-community/preservation";
  };

  outputs =
    { nixpkgs, nixy, ... }@inputs:
    let
      lib = nixpkgs.lib;
      cluster = nixy.eval lib {
        imports = [
          ./traits
          ./nodes
        ];
        args = { inherit inputs; };
      };
    in
    {
      nixosConfigurations = lib.mapAttrs (
        _: node:
        lib.nixosSystem {
          system = node.meta.system;
          modules = [ node.module ];
        }
      ) cluster.nodes;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;

      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-tree;

      packages.x86_64-linux =
        let
          imageConfig = lib.nixosSystem {
            system = "aarch64-linux";
            modules = [ cluster.nodes.Image.module ];
          };
          isoConfig = lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ cluster.nodes.iso.module ];
          };
        in
        {
          diskoImage = imageConfig.config.system.build.diskoImages;
          iso = isoConfig.config.system.build.isoImage;
        };
    };
}
