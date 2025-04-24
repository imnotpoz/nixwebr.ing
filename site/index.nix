{
  h2,
  pkgs,
  webringMembers,
  ...
}: let
  inherit (pkgs) lib;

  inherit (builtins) toString;
  inherit (lib.attrsets) hasAttr;
  inherit (lib.lists) length map;
  inherit (lib.strings) concatStrings optionalString;
in {
  template = "passthrough";
  format = "html";

  output = /*html*/''
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <title>nix webring</title>
        <link rel="icon" type="image/svg" href="/nix-webring.svg">
        <link rel="stylesheet" href="/index.css">
        <meta property="og:title" content="nix webring">
        <meta property="og:image" content="https://nixwebr.ing/nix-webring.svg">
        <meta property="og:type" content="website">
        <meta property="og:url" content="https://nixwebr.ing">
        <script defer data-domain="nixwebr.ing" src="https://plausible.poz.pet/js/script.js"></script>
      </head>
      <body>
        <div id="logo-and-name-and-shit">
          <h1>nix webring</h1>
          <img src="/nix-webring.svg" alt="nix webring logo">
        </div>

        ${h2 "webring members"}
        <ul>
          ${concatStrings (map (member: let
            hasConfig = hasAttr "config" member;
          in /*html*/''
            <li>
              <div class="webring-member">
                <a href="${member.site}">${member.name}</a>
                ${optionalString hasConfig /*html*/''
                  <a href="${member.config}"><img class="config-image" src="/nix.svg" alt="their nixos config"></a>
                ''}
              </div>
            </li>
          '') webringMembers)}
        </ul>

        ${h2 "about"}
        <p>
          this is a webring for people passionate about <a href="https://nix.dev/">nix</a>/<a href="https://nixos.org/">os</a>
          <br><br>
          it also allows you to link your nix configs, acting as a sort of repository for them
          <br><br>
          there are currently ${toString (length webringMembers)} members
        </p>

        ${h2 "joining"}
        <p>
          to join, have a personal website (bonus points if it uses nix!) and add the following links to it (they have to be on the main page):
        </p>
        <ul>
          <li>webring site: <code>https://nixwebr.ing</code></li>
          <li>next site: <code>https://nixwebr.ing/next/&lt;name&gt;</code></li>
          <li>previous site: <code>https://nixwebr.ing/prev/&lt;name&gt;</code></li>
          <li>random site (optional): <code>https://nixwebr.ing/rand</code></li>
        </ul>
        <p>
          and make a PR to one of <a href="https://codeberg.org/poz/nixwebr.ing">the</a> <a href="https://github.com/jacekpoz/nixwebr.ing">repos</a> adding yourself to the <code>webring.nix</code> file:
          <br>
          <code>{ name = "name"; site = "https://mysite.tld"; config = "https://gitforge.tld/name/nixos"; }</code>
          <br>
          linking your nixos config is entirely optional! (you'll be way cooler though)
        </p>

        ${h2 "does it work?"}
        <p>
          if you misspell your name in the links or the PR hasn't been merged yet, the next and prev links will lead to <code>https://nixwebr.ing/</code>
        </p>

        ${h2 "support"}
        <p>
          if you don't know how to / can't make a PR for some reason feel free to <a href="https://poz.pet/profiles.html">contact me</a>, I can add you to the webring myself
        </p>
      </body>
    </html>
  '';
}
