{ config, pkgs, lib, ... }:

let
  cfg = config.services.xserver.desktopManager.nide;
in {

  options = {};

  config = lib.mkIf cfg.enable {

    services.autorandr.enable = true;

    environment.systemPackages = with pkgs; [
      autorandr
    ];

  };

}
