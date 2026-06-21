{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    lanzaboote = {
      # pull upstream fix blocking evaluation
      url = "github:nix-community/lanzaboote/001e560fffc8f0235e9db20ebeb4ccde0ade1caf";
      # Optional but recommended to limit the size of your system closure
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };

    #Sienna builds stable
    nixpkgs-stable.url = github:NixOS/nixpkgs/nixos-26.05;
    lanzaboote-stable = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      # Optional but recommended to limit the size of your system closure
      inputs = { nixpkgs.follows = "nixpkgs-stable"; };
    };
  };
  outputs = { self, nixpkgs, nixpkgs-stable, ... }@inputs: {

    # Hostnames
    nixosConfigurations = {

      Auburn = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./Auburn ];
      };

      Sienna= nixpkgs-stable.lib.nixosSystem {
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
