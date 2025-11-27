{
  lib,
  craneLib,
  pkg-config,
  openssl,
  ...
}: let
  pname = "nixwebring-server";
in craneLib.buildPackage {
  inherit pname;
  version = "0.1.0";
  
  src = builtins.path {
    path = ./.;
    name = "${pname}-source";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  meta = {
    description = "Backend for the nix webring";
    homepage = "https://nixwebr.ing";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.poz ];
    mainProgram = "nixwebring-server";
  };
}
