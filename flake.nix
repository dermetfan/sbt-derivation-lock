{
  inputs.sbt-derivation.url = github:zaninime/sbt-derivation;

  outputs = { sbt-derivation, ... }: {
    overlay = final: prev: {
      sbt = prev.sbt.overrideAttrs (oldAttrs: {
        passthru = oldAttrs.passthru or {} // {
          mkDerivation = prev.callPackage ./sbt-derivation.nix { inherit sbt-derivation; };
        };
      });
    };
  };
}
