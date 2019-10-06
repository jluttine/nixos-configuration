{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;


in {

  options = with lib; {

    services.xserver.desktopManager.nide = {};

  };

  config = lib.mkIf cfg.enable {

    # Add DejaVu font and same fonts as Plasma
    fonts.fonts = with pkgs; [
      dejavu_fonts
      noto-fonts
      hack-font
    ];

    # These are the same fonts as Plasma uses
    fonts.fontconfig.defaultFonts = {
      monospace = [ "Hack" "Noto Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };

    # There also is the (new) i3-dmenu-desktop which only displays applications
    # shipping a .desktop file. It is a wrapper around dmenu, so you need that
    # installed.
    services.xserver.desktopManager.nide.i3Config = ''
      set $mod Mod4

      font pango:DejaVu Sans Mono 8

      bindsym $mod+space exec ${pkgs.rofi}/bin/rofi -show drun -modi drun#run -matching fuzzy -show-icons

      floating_modifier $mod

      hide_edge_borders smart

      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+r restart; exec ${pkgs.polybar}/bin/polybar-msg cmd restart
    '';
      #default_border none

    # Other core apps for making a complete desktop environment experience.
    environment.systemPackages = with pkgs; [
      rofi
    ];

  };

}
