
# How to use
## Import valheim flake like this
```
{
  description = "a valheim server";
  inputs.valheim-nix = {
      url = "github:rschardt/valheim-nix";
  };

  outputs = { self, nixpkgs, valheim-nix }: {
    nixosConfigurations.<your-hostname> = nixpkgs.lib.nixosSystem {
      modules = [
        valheim-nix.nixosModules.valheim
      ];
    };
  };
}
```
## Specifiy example valheim service in config
```
{
  ...
  services.valheim = {
    enable = true;
    public = false;
    secret = "yourSecret";
    world = "yourWorldName";
    servername = "yourServerName";
    adminList = ''
		yourSteamID
    '';
    #bannedList = "";
    #permittedList =  "";
  };
}
```
