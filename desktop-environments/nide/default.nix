{ config, pkgs, lib, ... }:

# NIDE = NixOS i3 Desktop Environment
#
# In Finnish, "nide" means a book or a volume.
#
# In English, "nide" means a group/family/nestful of pheasants.

let

  cfg = config.services.xserver.desktopManager.nide;

  # Write the i3 configuration file. Write the config file to
  # $XDG_CONFIG_DIRS/i3/config. Don't use explicit windowManager.i3.configFile
  # option because we don't want the path to change on every rebuild, so we can
  # just use i3 to reload its own configs.
  i3Config = pkgs.writeTextFile {
    name = "i3-config";
    text = cfg.i3Config;
    destination = "/etc/xdg/i3/config";
  };

in {

  #imports = lib.optionals cfg.enable [
  imports = [
    ./core.nix
    ./windows.nix
    ./workspaces.nix
    ./notifications.nix
    ./mounting.nix
    ./network.nix
    ./keyring.nix
    ./screensaver.nix
    ./brightness.nix
    ./volume.nix
    ./keyboard.nix
    ./monitor.nix
    ./kill.nix
    ./apps.nix
    ./bar.nix
  ];

  # TODO: Make modifier key configurable
  options = with lib; {
    services.xserver.desktopManager.nide = {
      enable = mkEnableOption "NIDE Desktop Manager";
      i3Config = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra i3 configuration.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.user.targets.nide = {
      requires = [ "graphical-session.target" ];
      unitConfig = {
        RefuseManualStart = false;
        StopWhenUnneeded = false;
      };
    };

    services.xserver.enable = true;
    services.xserver.desktopManager.session = lib.singleton {
      manage = "desktop";
      name = "nide";
      bgSupport = false; # WHAT IS THIS???
      start = ''
        ${pkgs.i3}/bin/i3 &
        waitPID=$!

        until ${pkgs.i3}/bin/i3-msg
        do
          echo "Waiting for i3 socket.."
        done

        systemctl --user start nide.target
        ${pkgs.dex}/bin/dex -a
      '';
    };

    # dex is used to autostart apps.. not very nice though.
        #${pkgs.dbus}/bin/dbus-send --session --dest=org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.DBus.Peer.Ping

    environment.systemPackages = with pkgs; [
      i3
      i3Config
      gnome3.adwaita-icon-theme
    ];

  };

}
