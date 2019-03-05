with import <nixpkgs> { }; {
  conveyorEnv = std.mkDerivation {
    name = "conveyor-env";
    buildInputs = [
      stdenv
      python3
    ] ++ (with python3Packages; [
      guessit
      requests
    ]) ++ (with goPackages; [
      rclone.bin
    ]);
  };
}
