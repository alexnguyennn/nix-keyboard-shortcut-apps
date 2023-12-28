inputs: pkgs:
let inherit (pkgs) callPackage; in
{} // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  kmonad = inputs.kmonad.overlays.default;
  Karabiner-DriverKit-VirtualHIDDevice = callPackage
    ./darwin/Karabiner-DriverKit-VirtualHIDDevice
    { Karabiner-DriverKit-VirtualHIDDevice-src = inputs.kmonad + "/../c_src/mac/Karabiner-DriverKit-VirtualHIDDevice"; };
  kmonad-daemon-shim = callPackage ./darwin/kmonad-daemon-shim { };
}
