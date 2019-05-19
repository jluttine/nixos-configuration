{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;


in {

  options = with lib; {

    services.xserver.desktopManager.vaakko = {};

  };

  config = lib.mkIf cfg.enable {

    systemd.user.services.udiskie = {
      description = "Udiskie daemon";
      wantedBy = [ "vaakko.target" ];
      partOf = [ "vaakko.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.udiskie}/bin/udiskie --no-automount --tray";
      };
    };

    # Other core apps for making a complete desktop environment experience.
    environment.systemPackages = with pkgs; [
      udiskie
    ];

  };

}
