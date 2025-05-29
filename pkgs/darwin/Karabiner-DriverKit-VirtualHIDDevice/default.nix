{ Karabiner-DriverKit-VirtualHIDDevice-src, pkgs, cpio, stdenv, xar }:

stdenv.mkDerivation {
  pname = "Karabiner-DriverKit-VirtualHIDDevice";
  version = "5.0.0";
  # use /raw/main/dist/* from filetree
  src = pkgs.fetchurl {
    url =
      "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/raw/main/dist/Karabiner-DriverKit-VirtualHIDDevice-5.0.0.pkg";
    sha256 = "sha256-hKi2gmIdtjl/ZaS7RPpkpSjb+7eT0259sbUUbrn5mMc";
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
