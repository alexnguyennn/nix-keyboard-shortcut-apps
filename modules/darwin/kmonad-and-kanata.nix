{ pkgs, config, lib, driverKitExtVersion, ... }:
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
      # # roughly: if you don't have the paths, we haven't been activated
      # if we are activating, make sure the service is not also getting started if it doesn't have input monitoring permissions?
      # if we are activating
      # can we check input monitoring permissions from cli? no
      system.activationScripts.applications.text = pkgs.lib.mkForce (''
        DEST_PATH=${karabinerDriverKitExtDestPath}
        echo "Checking if Karabiner DriverKit VirtualHIDDevice needs to be installed..."
        echo "Checking destination path: $DEST_PATH"
        echo "Expected version: ${driverKitExtVersion}"
        if [ -d "$DEST_PATH" ]; then
            CURRENT_VERSION=$(defaults read "$DEST_PATH/Contents/Info" CFBundleVersion | tr -d '\n')
        else
            CURRENT_VERSION=null
        fi
        if [ ! -d "$DEST_PATH" ] || [ "$CURRENT_VERSION" != "${driverKitExtVersion}" ]; then
            echo "Current version found: $CURRENT_VERSION"
            echo "Destination path does not exist or version mismatch."
            echo "Installing Karabiner DriverKit VirtualHIDDevice..."
            /usr/sbin/installer -pkg ${pkgs.Karabiner-DriverKit-VirtualHIDDevice}/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg -target /
            MACOS_PATH="$DEST_PATH/Contents/MacOS"
            echo "Removing quarantine attributes..."
            xattr -dr com.apple.quarantine "$DEST_PATH"
            echo activating dext...
            $MACOS_PATH/Karabiner-VirtualHIDDevice-Manager activate
            printf '\x1b[0;31mPlease grant Input Monitoring permissions to ${pkgs.bash} in System Preferences > Security & Privacy > Privacy > Input Monitoring\x1b[0m\n'
            if launchctl print "gui/$(id -u)/org.nixos.kanata-user" > /dev/null; then
              USER=$(stat -f %u /dev/console)
              printf '\x1b[0;31mFound running kanata user agent. Unloading in case input monitoring permissions are missing on latest activation - will need to manually reload with..\x1b[0m\n'
              printf '\x1b[0;31mlaunchctl bootstrap gui/%s ~/Library/LaunchAgents/org.nixos.kanata-user.plist\x1b[0m\n' "$USER"
              # Use sudo to run launchctl as the user who owns the GUI session
              sudo -u "#$USER" launchctl bootout "gui/$USER/org.nixos.kanata-user"
            fi
        fi
        echo "Completed Karabiner DriverKit VirtualHIDDevice activation"
      '');

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
