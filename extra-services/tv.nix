
{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.tv = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.tv {

    services.tvheadend.enable = true;
    networking.firewall.allowedTCPPorts = [
      9981 9982
    ];

  };

}
