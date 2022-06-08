{
  writeShellApplication,
  pkgs,
  lib,
  doCheck ? false,
  sbt,
  flakeOutput,
}:

writeShellApplication {
  name = "lock-deps";
  runtimeInputs = [sbt] ++ (with pkgs; [
    nix
    jq
    fd
    gnused
    gnugrep
    strip-nondeterminism
    file
    findutils
    git
    gnutar
    zstd
    curl
  ]);

  text = ''
    set -x

    REPO_DIR=$(git rev-parse --show-toplevel)
    LOCK_FILE="$REPO_DIR/deps.lock"

    cd "$REPO_DIR"
    rm -rf .nix
  '' + lib.optionalString doCheck ''
    lock_hash=$(nix hash file "$LOCK_FILE")
  '' + ''
    #shellcheck disable=SC2016
    nix develop -i "$REPO_DIR#${flakeOutput}.depsDerivation" --accept-flake-config -c -- bash -c 'eval "runHook () { :; }; ''${buildPhase:-buildPhase}"'

    cd .nix/coursier-cache/https
    #shellcheck disable=SC2207
    deps=($(fd -e pom -e xml -e jar -e sha1 -t f . --strip-cwd-prefix))

    for dep in "''${deps[@]}"; do
      (
        echo '{"fetch": {"url": "https://'"$dep"'", "sha256": "'"$(nix hash file "$dep")"'"}, "path": "'"$dep"'"}'

        # We need to fetch compiler bridge sources as well
        if [[ ''${dep##*/} =~ compiler-bridge && ''${dep##*.} == "jar" ]] && ! [[ $dep =~ -sources.jar ]]; then
          dep="''${dep%.*}-sources.jar"
          if ! [[ -f $dep ]]; then
            echo '{"fetch": {"url": "https://'"$dep"'", "sha256": "'"$(curl --silent https://"$dep" | nix hash file /dev/stdin)"'"}, "path": "'"$dep"'"}'
          fi
        fi
      ) &
    done | jq -c -s 'sort_by(.path) | . | unique' >"$LOCK_FILE"

    if [[ -v lock_hash ]]; then
      if [[ $(nix hash file "$LOCK_FILE") == "$lock_hash" ]]; then
        exit 0
      else
        echo >&2 "error: lock file is out of date"
        exit 1
      fi
    fi
  '';
}
