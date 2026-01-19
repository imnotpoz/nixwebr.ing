{
  lib,
  craneLib,
  ...
}: let
  pname = "nixwebring-server";
  version = "0.1.0";
in craneLib.buildPackage {
  inherit pname version;
  
  src = builtins.path {
    path = ./.;
    name = "${pname}-${version}-source";
  };

  meta = {
    description = "Backend for the nix webring";
    homepage = "https://nixwebr.ing";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.poz ];
    mainProgram = "nixwebring-server";
  };
}
