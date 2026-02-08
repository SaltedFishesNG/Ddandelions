{ inputs, ... }:
{
  traits = [
    {
      name = "nixvim";
      module =
        { conf, ... }:
        {
          imports = [ inputs.nixvim.nixosModules.nixvim ];

          programs.nixvim = {
            enable = true;
          };
        };
    }
  ];
}
