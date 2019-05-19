{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;

  # Write the i3 configuration file.
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
    ./kill.nix
    ./apps.nix
  ];

  # TODO: Make modifier key configurable
  options = with lib; {
    services.xserver.desktopManager.vaakko = {
      enable = mkEnableOption "Vaakko Desktop Manager";
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

    systemd.user.targets.vaakko = {
      requires = [ "graphical-session.target" ];
      unitConfig = {
        RefuseManualStart = false;
        StopWhenUnneeded = false;
      };
    };

    services.xserver.enable = true;
    services.xserver.desktopManager.session = lib.singleton {
      manage = "desktop";
      name = "vaakko";
      bgSupport = false; # WHAT IS THIS???
      start = let
        setxkbmap = "${pkgs.xlibs.setxkbmap}/bin/setxkbmap";

        startKbdd = pkgs.writeScript "start-kbdd" ''
          #!${pkgs.bash}/bin/bash
          set -eo pipefail
          ${pkgs.kbdd}/bin/kbdd --nodaemon 2>&1 | tee >(
            while read line
            do
              if [[ $line == 'EWMH is not supported: switching to generic' ]]
              then
                echo "Error: EWMH required but support not found."
                ${pkgs.procps}/bin/pkill -g 0
                exit 1
              fi
            done
          )

        '';

      in ''
        ${pkgs.i3}/bin/i3 &
        waitPID=$!

        systemctl --user start vaakko.target
      '';
    };

    environment.systemPackages = with pkgs; [
      i3
      i3Config
    ];
    # services.xserver = {
    #   desktopManager.xterm.enable = false;
    #   windowManager.i3 = {
    #     enable = true;
    #     # package = pkgs.i3-gaps;
    #     extraPackages = with pkgs; [

    #       # Write the config file to $XDG_CONFIG_DIRS/i3/config. Don't use
    #       # explicit windowManager.i3.configFile option because we don't want
    #       # the path to change on every rebuild, so we can just use i3 to reload
    #       # its own configs.
    #       i3Config


    #     ];
    #   };
    # };

  };

}
