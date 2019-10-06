{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;

in {

  options = {};

  config = lib.mkIf cfg.enable {

    services.xserver.desktopManager.nide.i3Config = let
      pasystray = "${pkgs.pasystray}/bin/pasystray";
      pactl = "${config.hardware.pulseaudio.package}/bin/pactl";
      sink = "@DEFAULT_SINK@";
    in ''
      exec_always --no-startup-id ${pasystray}

      bindsym XF86AudioMute exec ${pactl} set-sink-mute ${sink} toggle
      bindsym XF86AudioRaiseVolume exec ${pactl} set-sink-mute ${sink} 0; exec ${pactl} set-sink-volume ${sink} +5%
      bindsym XF86AudioLowerVolume exec ${pactl} set-sink-mute ${sink} 0; exec ${pactl} set-sink-volume ${sink} -5%
    '';

  };

}
