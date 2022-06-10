inputs:

final: prev: {
  sbt = prev.sbt.overrideAttrs (oldAttrs: {
    passthru = oldAttrs.passthru or {} // {
      mkDerivation = prev.callPackage ./sbt-derivation.nix { inherit (inputs) sbt-derivation; };
    };
  });
}
