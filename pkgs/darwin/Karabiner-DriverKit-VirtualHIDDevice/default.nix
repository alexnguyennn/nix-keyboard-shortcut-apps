{ Karabiner-DriverKit-VirtualHIDDevice-src, pkgs, cpio, stdenv, xar }:

stdenv.mkDerivation {
  pname = "Karabiner-DriverKit-VirtualHIDDevice";
  version = "2.1.0";
  # use /raw/main/dist/* from filetree
  src = pkgs.fetchurl {
    # full path: "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/raw/main/dist/Karabiner-DriverKit-VirtualHIDDevice-2.1.0.pkg";
    url =
      "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/raw/main/dist/Karabiner-DriverKit-VirtualHIDDevice-2.1.0.pkg";
    sha256 = "sha256-sv88fm90bF5BwL8jcbst/U5Iu4geusmbk1q8IVQdDIo=";
  };

  buildInputs = [ cpio xar ];
  unpackPhase = ''
    xar -xf $src
    mv Payload Payload.gz
    gzip -d Payload.gz
    mkdir extracted && cd extracted && cpio -i < ../Payload
  '';
  dontBuild = true;
  installPhase = ''
    cp -r . $out
  '';
}
