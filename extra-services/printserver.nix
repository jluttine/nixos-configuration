
{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.printServer = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.printServer {

    networking.firewall = {
      allowedTCPPorts = [ 631 ];
      allowedUDPPorts = [ 631 ];
    };

    services = {
      printing = {
        enable = true;
        browsing = true;
        defaultShared = true;
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
