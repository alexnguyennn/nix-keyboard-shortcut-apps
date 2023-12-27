inputs: pkgs:
let inherit (pkgs) callPackage; in
{} // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  Karabiner-DriverKit-VirtualHIDDevice = callPackage
    ./darwin/Karabiner-DriverKit-VirtualHIDDevice {};
  kmonad-daemon-shim = callPackage ./darwin/kmonad-daemon-shim { };
}
