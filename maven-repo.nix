{
  lib,
  runCommand,
  writeText,
  lockFile, # path to deps.lock
}: let
  lock = lib.importJSON lockFile;

  dependencies = writeText "sbt-dependencies" (
    builtins.concatStringsSep "\n"
    (__attrValues (__mapAttrs (dep: "${dep.path}:${builtins.fetchurl dep.fetch}") lock))
  );
in
  runCommand "maven-repo" {} ''
    mkdir $out
    for pair in $(< ${dependencies}); do
      IFS=':' read path store <<< "$pair"
      path="''${path#*/*/}"
      mkdir -p "$out/''${path%/*}"
      ln -s "$store" "$out/$path"
    done
  ''
