{
  description = "nixos-hardware";

  outputs = _: {
    nixosModules = {
      valheim = import ./modules/valheim.nix;
    };
  };
}
