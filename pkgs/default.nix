inputs: pkgs:
let
  inherit (pkgs) callPackage;
  # Define the base URL and version for easy updates
  version = "0.4.1";
  packageName = "kanata-tray";
  baseURL =
    "https://github.com/rszyma/kanata-tray/releases/download/v${version}/${packageName}";
  oldPkgs = import (builtins.fetchGit {
    # Descriptive name to make the store path easier to identify
    name = "kanata-old-revision";
    url = "https://github.com/NixOS/nixpkgs/";
    ref = "refs/heads/nixpkgs-unstable";
    rev =
      "92d295f588631b0db2da509f381b4fb1e74173c5"; # 1.5.0: https://www.nixhub.io/packages/kanata
  }) {
    config = { };
    overlays = [ ];
    inherit (pkgs) system;
  };

in { } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  Karabiner-DriverKit-VirtualHIDDevice =
    callPackage ./darwin/Karabiner-DriverKit-VirtualHIDDevice {
      Karabiner-DriverKit-VirtualHIDDevice-src = inputs.kmonad
        + "/../c_src/mac/Karabiner-DriverKit-VirtualHIDDevice";
    };
  kmonad-daemon-shim = callPackage ./darwin/kmonad-daemon-shim { };

  kanata = oldPkgs.kanata-with-cmd;

  kanata-tray = pkgs.stdenv.mkDerivation {
    pname = "kanata-tray";
    inherit version;

    # Conditional download URL based on the system type
    src = builtins.fetchurl (if pkgs.stdenv.isDarwin then {
      url = "${baseURL}-macos";
      sha256 =
        "633d8ad7d5b84cca62e02fef9852adbf952fb95fc49f66c04609364b2375c61a";
    } else if pkgs.stdenv.isLinux then {
      url = "${baseURL}-linux";
      sha256 =
        "34b296526ecf2a115d456f15d8fc74782ab4add72f8dd0559557a08feabf299c";
    } else {
      url = throw "Unsupported system for ${packageName}";
      sha256 = throw "Unsupported system for ${packageName}";
    });

    # Specify that this is a binary-only package
    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${packageName}
      chmod +x $out/bin/${packageName}
    '';

    # Optional: metadata for description, license, etc.
    meta = {
      description = "Kanata Tray - a tray icon application for Kanata";
      homepage = "https://github.com/rszyma/kanata-tray";
      platforms =
        [ "aarch64-linux" "aarch64-darwin" "x86_64-linux" "x86_64-darwin" ];
    };
  };

}
