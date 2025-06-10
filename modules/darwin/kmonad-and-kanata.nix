{ pkgs, config, lib, ... }:
let
  cfg = config.alexnguyennn.flake;
  kmonadCfg = cfg.kmonad;
  kanataCfg = cfg.kanata;
  kanataPath = "${pkgs.kanata}/bin/kanata";
  karabinerDriverKitExtDestPath =
    "/Applications/.Karabiner-VirtualHIDDevice-Manager.app";
  karabinerFilesPath =
    "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
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

  config = lib.mkMerge [
    (lib.mkIf (kmonadCfg.enable || kanataCfg.enable) {
      # kmonad setup
      # follows https://github.com/mtoohey31/nixexprs/blob/main/nix-darwin/modules/mtoohey/kmonad.nix
      system.activationScripts.applications.text = pkgs.lib.mkForce (''
        DEST_PATH=${karabinerDriverKitExtDestPath}
        if [ ! -d "$DEST_PATH" ]; then
              echo "Installing Karabiner DriverKit VirtualHIDDevice..."
              /usr/sbin/installer -pkg ${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Karabiner-DriverKit-VirtualHIDDevice.pkg -target /
        fi
        echo copying shim...
        cp --no-preserve mode ${pkgs.karabiner-daemon-shim}/bin/karabiner-daemon-shim $DEST_PATH/karabiner-daemon-shim
        # make service shim usable
        chmod u=rwx,og= $DEST_PATH/karabiner-daemon-shim
        chown root $DEST_PATH/karabiner-daemon-shim
        echo activating dext...
        $DEST_PATH/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
        printf '\x1b[0;31mPlease grant Input Monitoring permissions to /Applications/.Karabiner-VirtualHIDDevice-Manager.app/karabiner-daemon-shim in System Preferences > Security & Privacy > Privacy > Input Monitoring\x1b[0m\n'
        printf '\x1b[0;31mPlease grant Input Monitoring permissions to ${pkgs.bash} in System Preferences > Security & Privacy > Privacy > Input Monitoring\x1b[0m\n'
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

      launchd.user.agents.kanata-user = let
        kanataWrapper = pkgs.writeShellScript "kanata-wrapper" ''
          # Start Karabiner daemon in background
          echo "started kanata wrapper"

          exec sudo '${karabinerFilesPath}/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon' &

          # Give daemon time to initialize
          echo "started daemon"

          sleep 2
          echo "waited 2s for initialise - running kanata now"

          # Start Kanata (this becomes the main process)
          exec sudo ${kanataPath} --cfg ${kanataCfg.configPath} --nodelay
        '';

      in lib.mkIf (kanataCfg.loadService && kanataCfg.enable) {
        command = "${kanataWrapper}";
        serviceConfig = {

          UserName = "alex";
          RunAtLoad = true;
          KeepAlive = {
            SuccessfulExit = false;
            Crashed = true;
          };
          StandardErrorPath = "/Users/alex/.logs/kanata.err.log";
          StandardOutPath = "/Users/alex/.logs/kanata.out.log";
          ProcessType = "Interactive";
          Nice = -30;
        };
      };

      security.sudo.extraConfig = ''
        %admin ALL=(root) NOPASSWD: ${kanataPath} --cfg ${kanataCfg.configPath} --nodelay
        %admin ALL=(root) NOPASSWD: /Library/Application\ Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon
      '';
    })
    (lib.mkIf (!kmonadCfg.enable && !kanataCfg.enable) {
      # deactivation logic
      #
      system.activationScripts.applications.text = pkgs.lib.mkForce (''
        if [ -d "${karabinerDriverKitExtDestPath}" ] || [ -d "${karabinerFilesPath}" ]; then
          echo "Running Karabiner-DriverKit-VirtualHIDDevice uninstall process..."
          echo "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/#uninstallation"
          ${pkgs.bash}/bin/bash '${karabinerFilesPath}/scripts/uninstall/deactivate_driver.sh'
          ${pkgs.bash}/bin/bash '${karabinerFilesPath}/scripts/uninstall/remove_files.sh'
          killall Karabiner-VirtualHIDDevice-Daemon || true
          if [ -d "${karabinerDriverKitExtDestPath}" ]; then
            bcho "Removing Karabiner-VirtualHIDDevice-Manager.app..."
            sudo rm -rf "${karabinerDriverKitExtDestPath}"
          fi
        fi
        echo "Completed Karabiner-DriverKit-VirtualHIDDevice uninstall check"
      '');
    })
  ];
}
