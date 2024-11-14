{ pkgs, config, lib, ... }:
let
  cfg = config.alexnguyennn.flake;
  kmonadCfg = cfg.kmonad;
  kanataCfg = cfg.kanata;
in {
  options.alexnguyennn.flake.kmonad = {
    enable = lib.mkEnableOption "kmonad";
    loadService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description =
        "Enables launchd service. Disable this to ensure Karabiner-DriverKit-VirtualHIDDevice is installed without autoactivating kmonad";
    };
    baseConfig = lib.mkOption { type = lib.types.lines; };
    userConfig = lib.mkOption { type = lib.types.lines; };
  };

  options.alexnguyennn.flake.kanata = {
    enable = lib.mkEnableOption "kanata";
    loadService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description =
        "Enables launchd service. Disable this to ensure Karabiner-DriverKit-VirtualHIDDevice is installed without autoactivating kanata";
    };
    configPath = lib.mkOption {
      type = lib.types.str;
      default = true;
      description =
        "holds an absolute path to the config file to be used by kanata";
    };
  };

  config = lib.mkIf (kmonadCfg.enable || kanataCfg.enable) {

    # kmonad setup
    # follows https://github.com/mtoohey31/nixexprs/blob/main/nix-darwin/modules/mtoohey/kmonad.nix
    system.activationScripts.applications.text = pkgs.lib.mkForce (''
      echo copying dext...
      ${pkgs.rsync}/bin/rsync -a --delete ${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Applications/.Karabiner-VirtualHIDDevice-Manager.app /Applications
      echo copying shim...
      cp --no-preserve mode ${pkgs.karabiner-daemon-shim}/bin/karabiner-daemon-shim /Applications/.Karabiner-VirtualHIDDevice-Manager.app/karabiner-daemon-shim
      # make service shim usable
      chmod u=rwx,og= /Applications/.Karabiner-VirtualHIDDevice-Manager.app/karabiner-daemon-shim
      chown root /Applications/.Karabiner-VirtualHIDDevice-Manager.app/karabiner-daemon-shim
      echo activating dext...
      /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
      printf '\x1b[0;31mPlease grant Input Monitoring permissions to /Applications/.Karabiner-VirtualHIDDevice-Manager.app/karabiner-daemon-shim in System Preferences > Security & Privacy > Privacy > Input Monitoring\x1b[0m\n'

    '');

    # TODO: remove service itself when disabled by splitting to multiple config blocks
    launchd.daemons.kmonad-default.serviceConfig =
      lib.mkIf (kmonadCfg.loadService && kmonadCfg.enable) {
        EnvironmentVariables.PATH =
          "${pkgs.kmonad}/bin:${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-DriverKit-VirtualHIDDeviceClient.app/Contents/MacOS:${config.environment.systemPath}";
        KeepAlive = true;
        Nice = -20;
        ProgramArguments = [
          "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/karabiner-daemon-shim"
          "kmonad"
          "--input"
          ''iokit-name "Apple Internal Keyboard / Trackpad"''
          (toString (builtins.toFile "kmonad-default.kbd" ''
            ${kmonadCfg.baseConfig}
            ${kmonadCfg.userConfig}
          ''))
        ];

        StandardOutPath = "/Library/Logs/kanata/default-stdout";
        StandardErrorPath = "/Library/Logs/kanata/default-stderr";
        RunAtLoad = true;
      };

    launchd.daemons.kanata-default.serviceConfig =
      lib.mkIf (kanataCfg.loadService && kanataCfg.enable) {
        EnvironmentVariables.PATH =
          "${pkgs.kanata}/bin:${pkgs.kanata-tray}/bin:${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-DriverKit-VirtualHIDDeviceClient.app/Contents/MacOS:${config.environment.systemPath}";
        KeepAlive = {
          SuccessfulExit = false;
          Crashed = true;
          NetworkState = true;
        };
        Nice = -20;
        ProgramArguments = [
          "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/karabiner-daemon-shim"
          "kanata"
          "--port"
          "5829"
          "-c"
          kanataCfg.configPath
        ];

        StandardOutPath = "/Library/Logs/kanata/default-stdout";
        StandardErrorPath = "/Library/Logs/kanata/default-stderr";
        RunAtLoad = true;
      };
  };
}
