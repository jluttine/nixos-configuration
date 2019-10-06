{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;


in {

  options = with lib; {

    services.xserver.desktopManager.nide = {};

  };

  config = lib.mkIf cfg.enable {

    # Add DejaVu font
    fonts.fonts = with pkgs; [
      dejavu_fonts
    ];

    # There also is the (new) i3-dmenu-desktop which only displays applications
    # shipping a .desktop file. It is a wrapper around dmenu, so you need that
    # installed.
    services.xserver.desktopManager.nide.i3Config = ''
      set $mod Mod4

      font pango:DejaVu Sans Mono 8

      bindsym $mod+space exec ${pkgs.dmenu}/bin/dmenu_run

      floating_modifier $mod

      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+r restart

      bar {
              status_command i3status
      }
    '';

    #programs.nm-applet.enable = true;

    # Other core apps for making a complete desktop environment experience.
    environment.systemPackages = with pkgs; [
      dmenu #application launcher most people use
      i3status # gives you the default i3 status bar
      #networkmanagerapplet
    ];

  };

}
