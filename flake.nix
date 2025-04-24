{
  description = "the ring";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nte = {
      url = "git+https://git.poz.pet/poz/nte";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
  };

  outputs = { nixpkgs, nte, self, systems, ... }: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
    pkgsForEach = nixpkgs.legacyPackages;

    name = "nixwebr.ing";
    webringMembers = import ./webring.nix;
  in {
    packages = forEachSystem (
      system: let
        pkgs = pkgsForEach.${system};
      in {
        site = pkgs.callPackage ./site/default.nix {
          inherit (nte.functions.${system}) mkNteDerivation;
          inherit webringMembers;
        };
        server = pkgs.callPackage ./server/default.nix { };
      }
    );
    devShells = forEachSystem (
      system: let
        pkgs = pkgsForEach.${system};
        shell = pkgs.mkShell {
          inherit name;

          packages = with pkgs; [
            darkhttpd
          ];

          inputsFrom = [ self.packages.${system}.server ];
        };
      in {
        ${name} = shell;
        default = shell;
      }
    );
  };
}
