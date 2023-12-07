{
  description = "Valheim dedicated server";

  outputs = _: {
    nixosModules = {
      valheim = import ./modules/valheim.nix;
    };
  };
}
