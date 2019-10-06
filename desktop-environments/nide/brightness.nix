{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;

in {

  options = {};

  config = lib.mkIf cfg.enable {

    # Keybindings for adjusting monitor brightness. Adjusting brightness with
    # actkbd+light is nice because it's independent of X and works in ttys.
    services.actkbd = {
      enable = true;
      bindings = let
        light = "${pkgs.light}/bin/light";
        step = "10";
      in [
        {
          keys = [ 224 ];
          events = [ "key" ];
          # Use minimum brightness 0.1 so the display won't go totally black.
          command = "${light} -N 0.1 && ${light} -U ${step}";
        }
        {
          keys = [ 225 ];
          events = [ "key" ];
          command = "${light} -A ${step}";
        }
      ];
    };

    # Enable users to modify brightness. NOTE: User must belong to video group!
    # (These modify udev rules, so if you just enabled this, probably best to
    # reboot.)
    programs.light.enable = true;
    hardware.acpilight.enable = true;
    hardware.brightnessctl.enable = true;

  };

}
