{
  inputs.sbt-derivation.url = github:zaninime/sbt-derivation;

  outputs = inputs: {
    overlay = import ./overlay.nix inputs;
  };
}
