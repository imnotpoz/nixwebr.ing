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
      in {
        site = pkgs.callPackage ./site/package.nix {
          inherit (nte.functions.${system}) mkNteDerivation;
          inherit webringMembers;
        };
        server = pkgs.callPackage ./server/package.nix {
          craneLib = crane.mkLib pkgs;
        };
      }
    );
    devShells = forEachSystem (
      system: let
        pkgs = pkgsForEach.${system};
      in {
        ${name} = self.devShells.${system}.default;
        default = pkgs.mkShell {
          inherit name;

          packages = with pkgs; [
            darkhttpd
            rust-analyzer
            clippy
            geckodriver
            firefox-esr
          ];

          inputsFrom = [ self.packages.${system}.server ];
        };
      }
    );
  };
}
