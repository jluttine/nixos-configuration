{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;

in {

  options = with lib; { };

  config = lib.mkIf cfg.enable {

    nixpkgs.overlays = [
      (
        self: super: {
          polybar = super.polybar.override {
            i3Support = true;
            #mpdSupport = true;
            pulseSupport = true;
            #iwSupport = true;
            #githubSupport = true;
          };
        }
      )
    ];

    environment.systemPackages = with pkgs; [
      polybar
    ];

  };

}
