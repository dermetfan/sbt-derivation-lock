{ callPackage, writeText, sbt, makeWrapper, lockFile }:

let
  mavenRepo = callPackage ./maven-repo.nix { inherit lockFile; };

  repoConfig = writeText "repositories" ''
    [repositories]
      local
      nix-maven: file://${mavenRepo}
  '';
in
  sbt.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs or [] ++ [ makeWrapper ];
    postInstall = ''
      rm $out/bin/sbt
      makeWrapper $out/share/sbt/bin/sbt $out/bin/sbt \
        --add-flags '-Dsbt.repository.config=${repoConfig} -Dsbt.override.build.repos=true'
    '';
    passthru = oldAttrs.passthru or {} // { inherit mavenRepo repoConfig; };
  })
