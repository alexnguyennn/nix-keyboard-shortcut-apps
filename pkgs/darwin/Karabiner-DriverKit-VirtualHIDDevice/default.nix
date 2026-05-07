{ Karabiner-DriverKit-VirtualHIDDevice-src, pkgs, stdenv, driverKitExtVersion }:

stdenv.mkDerivation {
  pname = "Karabiner-DriverKit-VirtualHIDDevice";
  version = driverKitExtVersion;
  # use /raw/main/dist/* from filetree
  src = pkgs.fetchurl {
    url =
      "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/raw/main/dist/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg";
    sha256 = "sha256-noxGI58HSBYSQeQkRIV5ASJOXIL1tYoXMd9McL8HNqg=";
  };

  buildInputs = [ ];
  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg
  '';
}
