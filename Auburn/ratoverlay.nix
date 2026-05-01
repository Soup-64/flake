let
  ratoverlay = final: prev: {
  libratbag = prev.libratbag.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "jabjab";
      repo = "libratbag";
      rev = "38af81ca649f113df80d102ccdd7f262ed7d4124";
      hash = "sha256-ZMEdePA8ZSR/r5Yyd0TlWHZO9rIVxmGlgBX6rssVJy0=";
    };
  });
};
in
{
nixpkgs.overlays = [ ratoverlay ];
 services.ratbagd.enable = true;
 #environment.systemPackages = with pkgs; [
 #     libratbag
 #];
}
