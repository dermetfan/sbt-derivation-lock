{
  sbt-derivation,
  callPackage,
  sbt,
}:

{
  lockFile,
  flakeOutput, # ? "defaultPackage"
  ...
} @ args:

let
  lockedSbt = callPackage ./sbt.nix { inherit lockFile; };
  callMkDerivation = callPackage "${sbt-derivation}/lib/sbt-derivation.nix";

  sbtEnvSetupCmds = ''
    export SBT_DEPS=$(mktemp -d)
    export SBT_OPTS="-Dsbt.global.base=$SBT_DEPS/project/.sbtboot -Dsbt.boot.directory=$SBT_DEPS/project/.boot -Dsbt.ivy.home=$SBT_DEPS/project/.ivy $SBT_OPTS"
    export COURSIER_CACHE=$SBT_DEPS/project/.coursier
    mkdir -p $SBT_DEPS/project/{.sbtboot,.boot,.ivy,.coursier}
  '';
in

(callMkDerivation { sbt = lockedSbt; } (args // {
  depsSha256 = null;

  passthru = args.passthru or {} // {
    sbt = lockedSbt;

    lock-deps = callPackage ./lock-deps.nix { inherit flakeOutput; };

    # used by lock-deps
    depsDerivation = (callMkDerivation {} (args // {
      depsSha256 = null;
      depsWarmupCommand = ''
        runHook preDepsWarmupCommand
        sbt "dependencyList ; consoleQuick" <<< ":quit"
      '';
    })).deps.overrideAttrs (_: { outputHash = null; });
  };
})).overrideAttrs (oldAttrs: {
  # no longer needed
  deps = null;


  preConfigure = ''
    ${sbtEnvSetupCmds}

    # SBT expects a "local" prefix to each organization for plugins
    for repo in ${lockedSbt.mavenRepo}/sbt-plugin-releases/*; do
      ln -s $repo $SBT_DEPS/project/.ivy/local''${repo##*/}
    done
  '';

  # explicitly overwrite the `configurePhase` phase, otherwise it
  # references the now null `deps` derivation.
  configurePhase = ''
    ${args.configurePhase or ""}
    runHook preConfigure

    ${oldAttrs.passthru.dependencies.extractor} $SBT_DEPS

    runHook postConfigure
  '';
})
