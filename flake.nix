{
  description = "nixos-hardware";

  outputs = _: {
    nixosModules = {
      valheim = import ./modules/module-list.nix;
    };
  };
}
