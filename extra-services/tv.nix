
{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.tv = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.tv {

    # Tvheadend backend
    services.tvheadend.enable = true;
    networking.firewall.allowedTCPPorts = [
      9981 9982
    ];

    # Kodi frontend
    nixpkgs.config.kodi.enablePVRHTS = true;
    environment.systemPackages = with pkgs; [
      kodi
    ];

  };

}
