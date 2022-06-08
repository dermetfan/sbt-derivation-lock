{
  lib,
  runCommand,
  writeText,
  lockFile, # deps.lock
}: let
  lock = lib.importJSON lockFile;

  dependencies = writeText "sbt-dependencies" (
    builtins.concatStringsSep "\n"
    (map (dep: "${dep.path}:${builtins.fetchurl dep.fetch}") lock)
  );
in
  runCommand "maven-repo" {} ''
    for pair in $(< ${dependencies}); do
      IFS=':' read path store <<< "$pair"
      path="''${path#*/*/}"
      mkdir -p "$out/''${path%/*}"
      ln -s "$store" "$out/$path"
    done
  ''
