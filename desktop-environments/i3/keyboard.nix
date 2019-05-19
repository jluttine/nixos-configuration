{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;

  kbdd-daemon = pkgs.writeTextFile {
    name = "kbdd-daemon";
    destination = "/share/dbus-1/services/ru.gentoo.KbddService.service";
    text = ''
      [D-BUS Service]
      Name=ru.gentoo.KbddService
      Exec=${pkgs.kbdd}/bin/kbdd --nodaemon
      SystemdService=kbdd.service
    '';
  };

in {

  options = {};

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [

      # Just adding this to installed packages enables the D-Bus service.
      kbdd-daemon

    ];

    # Without this, D-Bus didn't seem to work.. Not sure though.
    services.xserver.startDbusSession = true;
    services.xserver.updateDbusEnvironment = true;

    # Keybinding for switching the keyboard layout
    services.xserver.desktopManager.vaakko.i3Config = let
      dbus-send = "${pkgs.dbus}/bin/dbus-send";
    in ''
      bindsym $mod+Shift+space exec ${dbus-send} --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.prev_layout
    '';

    # FIXME: These should be defined by the user, not the desktop environment.
    services.xserver.layout = "fi,us";
    services.xserver.xkbOptions = "caps:escape";

    #
    # TODO: For systray companion, see: https://hub.darcs.net/zabbal/ktc
    #

  };

}
