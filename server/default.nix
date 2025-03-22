{
  lib,
  rustPlatform,
  ...
}: rustPlatform.buildRustPackage {
  pname = "nixwebring-server";
  version = "0.1.0";
  
  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = {
    description = "Backend for the nix webring";
    homepage = "https://nixwebr.ing";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.jacekpoz ];
    mainProgram = "nixwebring-server";
  };
}
