{
  inputs = { 
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      # Optional but recommended to limit the size of your system closure
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: {

    # Hostnames
    nixosConfigurations = {

      Auburn = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./Auburn ];
      };

      Sienna= nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./Sienna ];
      };

      Selenium = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./Selenium ];
      };

    };
  };
}
