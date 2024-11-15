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
        # Should this be 192.168.10.10:631?
        listenAddresses = [ "*:631" ];
        drivers = [
          pkgs.gutenprint
          pkgs.hplip
        ];
      };
      avahi = {
        enable = false;
        publish = {
          enable = true;
          userServices = true;
        };
      };
    };
  };

}
