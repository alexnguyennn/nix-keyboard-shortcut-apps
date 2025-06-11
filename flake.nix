{
  description =
    "Nix flake set up that enables packages and system services that enable advanced keyboard shortcut configuration e.g. Kanata or KMonad";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    kmonad = {
      url = "git+https://github.com/kmonad/kmonad?submodules=1&dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      driverKitExtVersion = "5.0.0";
    in {
      darwinModule = import ./modules/darwin/kmonad-and-kanata.nix {
        inherit driverKitExtVersion;
      };
      overlays.default = nixpkgs.lib.composeManyExtensions [
        inputs.kmonad.overlays.default
        (_: prev:
          let pkgs = prev;
          in import ./pkgs inputs pkgs { inherit driverKitExtVersion; })
      ];
    };
}
