{
  sbt-derivation,
  sbt,
  callPackage,
  writeText,
  makeWrapper,
  mavenRepo,
}:

let
  repoConfig = writeText "repositories" ''
    [repositories]
      local
      nix-maven: file://${mavenRepo}
  '';
in
  (callPackage "${sbt-derivation}/pkgs/custom-sbt" {
    sbt = sbt.overrideAttrs (oldAttrs: {
      version = "0.0.0";
      nativeBuildInputs = oldAttrs.nativeBuildInputs or [] ++ [makeWrapper];
      postInstall = ''
        rm $out/bin/sbt
        makeWrapper $out/share/sbt/bin/sbt $out/bin/sbt \
          --add-flags '-Dsbt.repository.config=${repoConfig} -Dsbt.override.build.repos=true'
      '';
    });
  }).overrideAttrs (oldAttrs: {
    passthru = oldAttrs.passthru or {} // {
      mkDerivation = callPackage "${sbt-derivation}/pkgs/sbt-derivation" {};
    };
  })
