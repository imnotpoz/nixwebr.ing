{
  h2,
  h3,
  h4,
  ...
}: {
  template = "passthrough";
  format = "html";

  output = /*html*/''
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <title>nix webring - invalid member</title>
        <link rel="icon" type="image/svg" href="/nix-webring.svg">
        <link rel="stylesheet" href="/index.css">
        <meta property="og:title" content="nix webring">
        <meta property="og:image" content="https://nixwebr.ing/nix-webring.svg">
        <meta property="og:type" content="website">
        <meta property="og:url" content="https://nixwebr.ing/invalid-member.html">
        <script defer data-domain="nixwebr.ing" src="https://plausible.poz.pet/js/script.js"></script>
      </head>
      <body>
        ${h2 "invalid member!"}
        <p>
          if a nix webring <code>prev</code> or <code>next</code> link led you here
          it means that website isn't part of the webring <s>yet</s>!
          <br><br>
          this can be because of a few reasons listed below together with some
          troubleshooting tips if you're the owner of that website
          and are trying to join the nix webring
          <br><br>
          <a href="/">click here</a> to go back to the nix webring
        </p>
        <hr>
        ${h3 "your links are incorrect"}
        <p>
          the nix webring expects the <code>prev</code> and <code>next</code> links to be
          in the following formats:
        </p>
        <ul>
          <li><code>https://nixwebr.ing/prev/&lt;name&gt;</code></li>
          <li><code>https://nixwebr.ing/next/&lt;name&gt;</code></li>
        </ul>
        <p>
          where <code>&lt;name&gt;</code> is the name you used in <code>webring.nix</code>
          <br><br>
          <b>this is case sensitive!</b> e.g. <code>poz</code> and <code>Poz</code>
          are treated as 2 different names
        </p>
        ${h4 "how do I fix my links?"}
        <p>
          double check that your name in <code>webring.nix</code> matches the name you
          used in the nix webring links on your website <b>exactly</b>
          <br><br>
          example:
          <br>
          <pre><code># webring.nix
[
  # ...
  { name = "NixLover2137"; site = "https://example.org/nixlover"; }
  # ...
]</code></pre>
          <pre><code># https://example.org/nixlover
&lt;!-- ... --&gt;
&lt;a href="https://nixwebr.ing/prev/NixLover2137"&gt;prev&lt;/a&gt;
&lt;a href="https://nixwebr.ing/"&gt;nix webring&lt;/a&gt;
&lt;a href="https://nixwebr.ing/next/NixLover2137"&gt;next&lt;/a&gt;
&lt;!-- ... --&gt;</code></pre>
        </p>
        <hr>
        ${h3 "your PR hasn't been merged"}
        <p>
          this one is on me, I try to check both
          <a href="https://codeberg.org/poz/nixwebr.ing/pulls">codeberg</a>
          and <a href="https://github.com/imnotpoz/nixwebr.ing/pulls">github</a> PRs
          from time to time but sometimes I forget to do so or don't have time
        </p>
        ${h4 "how do I get my PR merged?"}
        <p>
          if you think I missed your PR or want to know
          an approximate time when I'm able to merge it, feel free to
          <a href="https://poz.pet/profiles.html">contact me</a>
          personally - outside of this, there's nothing else for you to do
        </p>
        <hr>
        ${h3 "other issues"}
        <p>
          it's possible this site doesn't cover all of the issues that can stop
          you from joining the nix webring - if you think that's the case please
          <a href="https://poz.pet/profiles.html">let me know</a> and I'll do my best
          to figure something out
        </p>
      </body>
    </html>
  '';
}
