{
  lib,
  mkNteDerivation,
  webringMembers,
  writeText,
  ...
}: let
  inherit (lib.attrsets) listToAttrs;
  inherit (lib.lists) map;
  inherit (lib.strings) replaceStrings toLower;

  h = n: content: let
    id = replaceStrings [" " ";" "?"] ["-" "-" ""] (toLower content);
  in /*html*/''
    <h${toString n} id="${id}"><a href="#${id}">#</a> ${content}</h${toString n}>
  '';

  hs = listToAttrs (map (n: {
    name = "h${toString n}";
    value = text: h n text;
  }) [ 1 2 3 4 5 6 ]);
in mkNteDerivation {
  name = "nixwebring-site";
  version = "0.1.0";
  src = ./.;

  extraArgs = hs // {
    inherit h webringMembers;
  };

  entries = [
    ./index.nix
    ./invalid-member.nix
  ];

  extraFiles = [
    { source = "./index.css"; destination = "/"; }
    { source = "./nix-webring.svg"; destination = "/"; }
    { source = "./nix.svg"; destination = "/"; }
    {
        source = writeText "webring.json" (builtins.toJSON webringMembers);
        destination = "/webring.json";
    }
  ];

  meta = {
    description = "Frontend for the nix webring";
    homepage = "https://nixwebr.ing";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.poz ];
  };
}
