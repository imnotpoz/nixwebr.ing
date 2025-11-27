{
  description = "the ring";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    nte = {
      url = "git+https://git.poz.pet/poz/nte";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, systems, nte, crane, ... }: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
    pkgsForEach = nixpkgs.legacyPackages;

    name = "nixwebr.ing";
    webringMembers = import ./webring.nix;
  in {
    packages = forEachSystem (
      system: let
        pkgs = pkgsForEach.${system};
        craneLib = crane.mkLib pkgs;
      in {
        site = pkgs.callPackage ./site/package.nix {
          inherit (nte.functions.${system}) mkNteDerivation;
          inherit webringMembers;
        };
        server = pkgs.callPackage ./server/package.nix { inherit craneLib; };
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
