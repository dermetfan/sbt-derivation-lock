self:

self.inputs.nixpkgs.lib.composeManyExtensions [
  self.inputs.sbt-derivation.overlay

  (final: prev: {
    sbt = prev.sbt.overrideAttrs (oldAttrs: {
      passthru = oldAttrs.passthru // {
        mkDerivation = args: let
          # local maven repo for SBT to fetch dependencies from; built from ./deps.lock
          mavenRepo = prev.callPackage ./maven-repo.nix {
            inherit (args) lockFile;
          };

          repoConfig = prev.writeText "repositories" ''
            [repositories]
              local
              nix-maven: file://${mavenRepo}
          '';

          sbt = prev.sbt.overrideAttrs (oldAttrs: {
            nativeBuildInputs = oldAttrs.nativeBuildInputs or [] ++ [ prev.makeWrapper ];
            postInstall = ''
              rm $out/bin/sbt
              makeWrapper $out/share/sbt/bin/sbt $out/bin/sbt \
                --add-flags '-Dsbt.repository.config=${repoConfig} -Dsbt.override.build.repos=true'
            '';
          });
        in (
          sbt.passthru.mkDerivation (args // {
            depsWarmupCommand = ''
              ${args.depsWarmupCommand or ""}
              sbt "dependencyList ; consoleQuick" <<< ":quit"
            '';
          })
        ).overrideAttrs (oldAttrs: {
          # no longer needed
          deps = null;

          # explicitly overwrite the `postConfigure` phase, otherwise it
          # references the now null `deps` derivation.
          postConfigure = ''
            mkdir -p .nix/ivy
            # SBT expects a "local" prefix to each organization for plugins
            for repo in ${mavenRepo}/sbt-plugin-releases/*; do
              ln -s $repo .nix/ivy/local''${repo##*/}
            done
          '';

          passthru = {
            inherit mavenRepo;
            inherit sbt;
            lock-deps = prev.callPackage ./lock-deps.nix {
              inherit (prev) sbt;
              inherit (args) flakeOutput;
            };
            # used by lock-deps
            depsDerivation = oldAttrs.deps.overrideAttrs (_: { outputHash = null; });
          };
        });
      };
    });
  })
]
