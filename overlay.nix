inputs:

final: prev: {
  sbt = prev.sbt.overrideAttrs (oldAttrs: {
    passthru = oldAttrs.passthru or {} // {
      inherit (prev.sbt) version;
      mkDerivation = prev.callPackage ./sbt-derivation.nix { inherit (inputs) sbt-derivation; };
    };
  });
}
