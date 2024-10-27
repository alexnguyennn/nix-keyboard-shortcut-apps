{ stdenv }:

stdenv.mkDerivation {
  pname = "karabiner-daemon-shim";
  version = "0.1.0";
  src = ./.;
  buildPhase = ''
    cc main.c -o karabiner-daemon-shim
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp karabiner-daemon-shim $out/bin
  '';
}
