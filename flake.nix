{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    sbt-derivation.url = github:zaninime/sbt-derivation;
  };

  outputs = { self, ... }: {
    overlay = import ./overlay.nix self;
  };
}
