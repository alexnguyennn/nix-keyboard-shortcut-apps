{
  # heavily ported from
  description = "KMonad nix flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    kmonad = {
      url = "git+https://github.com/kmonad/kmonad?submodules=1&dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    darwinModule = import ./modules/darwin/kmonad.nix;
    overlays.default = nixpkgs.lib.composeManyExtensions [
      inputs.kmonad.overlays.default
      (_: prev: let pkgs = prev; in import ./pkgs inputs pkgs)
    ];
  };
}
