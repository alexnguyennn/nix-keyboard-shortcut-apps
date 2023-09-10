{ pkgs, config, lib, ... }:
let
  cfg = config.alexnguyennn.flake.kmonad;
in
{
  options.alexnguyennn.flake.kmonad = {
    enable = lib.mkEnableOption "kmonad";
    baseConfig = lib.mkOption { type = lib.types.lines; };
    userConfig = lib.mkOption { type = lib.types.lines; };
  };

  config = lib.mkIf cfg.enable {

    # kmonad setup
    # follows https://github.com/mtoohey31/nixexprs/blob/main/nix-darwin/modules/mtoohey/kmonad.nix
    system.activationScripts.applications.text = pkgs.lib.mkForce (''
      echo copying dext...
      ${pkgs.rsync}/bin/rsync -a --delete ${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Applications/.Karabiner-VirtualHIDDevice-Manager.app /Applications
      echo copying shim...
      cp --no-preserve mode ${pkgs.kmonad-daemon-shim}/bin/kmonad-daemon-shim /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim
      # make service shim usable
      chmod u=rwx,og= /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim
      chown root /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim
      echo activating dext...
      /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
      printf '\x1b[0;31mPlease grant Input Monitoring permissions to /Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim in System Preferences > Security & Privacy > Privacy > Input Monitoring\x1b[0m\n'

    '');

    launchd.daemons.kmonad-default.serviceConfig = {
      EnvironmentVariables.PATH =
        "${pkgs.kmonad}/bin:${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-DriverKit-VirtualHIDDeviceClient.app/Contents/MacOS:${config.environment.systemPath}";
      KeepAlive = true;
      Nice = -20;
      ProgramArguments = [
        "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/kmonad-daemon-shim"
        "--input"
        ''iokit-name "Apple Internal Keyboard / Trackpad"''
        (toString (builtins.toFile "kmonad-default.kbd" ''
          ${cfg.baseConfig}
          ${cfg.userConfig}
        ''))
      ];

      # ${cfg.config}
      StandardOutPath = "/Library/Logs/KMonad/default-stdout";
      StandardErrorPath = "/Library/Logs/KMonad/default-stderr";
      RunAtLoad = true;
    };

  };

}
