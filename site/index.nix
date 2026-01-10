{
  h2,
  pkgs,
  webringMembers,
  ...
}: let
  inherit (pkgs) lib;

  inherit (builtins) toString;
  inherit (lib.attrsets) hasAttr;
  inherit (lib.lists) filter length imap0;
  inherit (lib.strings) concatStrings optionalString toJSON;

  configMembers = filter (hasAttr "config") webringMembers;
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
        <main>
          <div id="logo-and-name-and-shit">
            <h1>nix webring</h1>
            <img src="/nix-webring.svg" alt="nix webring logo">
          </div>

          ${h2 "webring members"}
          <p>
            all websites are automatically checked every 24 hours
            <br><br>
            hover over the status character to see the last checked time (UTC+1)
            <br><br>
            status characters:
            <span style="color: #019739;">+</span> - ok,
            <span style="color: #F8AD0D;">/</span> - broken links,
            <span style="color: #B80000;">x</span> - unreachable,
            <span style="color: #575757;">?</span> - unknown
          </p>
          <ul>
            ${concatStrings (imap0 (i: member: let
              hasConfig = hasAttr "config" member;
            in /*html*/''
              <li>
                <div class="webring-member">
                  <span class="webring-status" id="website-status-${toString i}"></span>
                  <a href="${member.site}">${member.name}</a>
                  ${optionalString hasConfig /*html*/''
                    <a href="${member.config}"><img class="config-image" src="/nix.svg" alt="their nixos config"></a>
                  ''}
                </div>
              </li>
            '') webringMembers)}
          </ul>

          <script>
            const members = ${toJSON webringMembers};
            for (let i = 0; i < members.length; ++i) {
              const name = members[i].name;
              fetch("/status/" + name).then(response => {
                response.text().then(text => {
                  const status = JSON.parse(text);
                  let statusChar = "";
                  let color = "";
                  switch (status.status) {
                    case "Ok":
                      statusChar = "+";
                      color = "#019739";
                      break;
                    case "BrokenLinks":
                      statusChar = "/";
                      color = "#F8AD0D";
                      break;
                    case "Unreachable":
                      statusChar = "x";
                      color = "#B80000";
                      break;
                    case "Unknown":
                      statusChar = "?";
                      color = "#575757";
                      break;
                    default:
                      break;
                  }

                  const span = document.getElementById("website-status-" + i);
                  span.textContent = statusChar;
                  span.style.color = color;
                  span.title = status.last_checked;
                });
              });
            }
          </script>

          ${h2 "updates"}
          <p>
            2025-05-07
            <br>
            removed <code>spoody</code> due to the website being broken
            <br>
            and <code>theholytachanka</code> due to missing webring links
            <br>
            contact me after fixing your issues or make a PR to get back in
          </p>

          ${h2 "about"}
          <p>
            this is a webring for people passionate about <a href="https://nix.dev/">nix</a>/<a href="https://nixos.org/">os</a>
            <br><br>
            it also allows you to link your nix configs, acting as a sort of repository for them
            <br><br>
            there are currently ${toString (length webringMembers)} members, ${toString (length configMembers)} of which link their configs!
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
            and make a PR to one of <a href="https://codeberg.org/poz/nixwebr.ing">the</a> <a href="https://github.com/imnotpoz/nixwebr.ing">repos</a> adding yourself to the <code>webring.nix</code> file:
            <br><br>
            <code>{ name = "name"; site = "https://mysite.tld"; config = "https://gitforge.tld/name/nixos"; }</code>
            <br><br>
            linking your nixos config is entirely optional! (you'll be way cooler though)
            <br><br>
            if you don't want to link your config, omit the <code>config</code> attribute entirely
          </p>

          ${h2 "does it work?"}
          <p>
            if you misspell your name in the links or the PR hasn't been merged yet, the next and prev links will lead to <code>https://nixwebr.ing/invalid-member.html</code>
          </p>

          ${h2 "support"}
          <p>
            if you don't know how to / can't make a PR for some reason feel free to <a href="https://poz.pet/profiles.html">contact me</a>, I can add you to the webring myself
          </p>
        </main>
      </body>
    </html>
  '';
}
