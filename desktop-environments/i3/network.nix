{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;


in {

  options = with lib; {};

  config = lib.mkIf cfg.enable {

    systemd.user.services.nm-applet = {
      description = "Network manager applet";
      wantedBy = [ "vaakko.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
        Restart = "always";
      };
    };

  };

}
