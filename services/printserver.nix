{ lib, config, pkgs, ... }:
{

  options.services.printServer.enable = lib.mkEnableOption "printing server";

  config = lib.mkIf config.services.printServer.enable {

    networking.firewall = {
      allowedTCPPorts = [ 631 ];
      allowedUDPPorts = [ 631 ];
    };

    services = {
      printing = {
        enable = true;
        browsing = true;
        defaultShared = true;
        listenAddresses = [ "*:631" ];
        drivers = [
          pkgs.gutenprint
          pkgs.hplip
        ];
      };
      avahi = {
        enable = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };
    };
  };

}
