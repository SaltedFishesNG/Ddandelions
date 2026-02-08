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
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forSystems = f: lib.genAttrs systems f;
      cluster = nixy.eval lib {
        imports = [
          ./traits
          ./nodes
        ];
        args = { inherit inputs; };
      };
      mkSystem =
        node:
        lib.nixosSystem {
          system = node.meta.system;
          modules = [ node.module ];
        };
      nixosSystems = lib.mapAttrs (_: mkSystem) cluster.nodes;
    in
    {
      nixosConfigurations = nixosSystems;
      formatter = forSystems (s: nixpkgs.legacyPackages.${s}.nixfmt-tree);
      packages = forSystems (s: {
        diskoImage = nixosSystems.Image.config.system.build.diskoImages;
        iso = nixosSystems.iso.config.system.build.isoImage;
      });
    };
}
