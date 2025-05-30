inputs: pkgs:
let
  inherit (pkgs) callPackage;
  # Define the base URL and version for easy updates
in { } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  Karabiner-DriverKit-VirtualHIDDevice =
    callPackage ./darwin/Karabiner-DriverKit-VirtualHIDDevice {
      Karabiner-DriverKit-VirtualHIDDevice-src = inputs.kmonad
        + "/../c_src/mac/Karabiner-DriverKit-VirtualHIDDevice";
    };
  karabiner-daemon-shim = callPackage ./darwin/karabiner-daemon-shim { };
}
