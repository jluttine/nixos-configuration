
{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.tv = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    domain = mkOption {
      type = types.str;
    };
    ssl = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = let
    cfg = config.localConfiguration.extraServices.tv;
  in mkIf cfg.enable {

    # Tvheadend backend
    services.tvheadend.enable = true;
    # NOTE: Don't open firewall, use Nginx as reverse proxy.

    # Kodi frontend
    nixpkgs.config.kodi.enablePVRHTS = true;
    environment.systemPackages = with pkgs; [
      kodi
    ];

    # Reverse proxy so we can have domain name and SSL
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = cfg.ssl;
        enableACME = cfg.ssl;
        locations = {
          "/" = {
            proxyPass = "http://localhost:9981/"; # The / is important!
          };
        };
      };
    };

  };

}
