{ lib, config, pkgs, ... }:
{

  options.services.tv = {
    enable = lib.mkEnableOption "TV service with tvheadend and kodi";
    domain = lib.mkOption {
      type = lib.types.str;
    };
    ssl = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = let
    cfg = config.services.tv;
  in lib.mkIf cfg.enable {

    # Tvheadend backend
    services.tvheadend.enable = true;
    # NOTE: Don't open firewall, use Nginx as reverse proxy.

    # Kodi frontend. See: https://nixos.wiki/wiki/Kodi
    environment.systemPackages = with pkgs; [
      (kodi.passthru.withPackages (kodiPkgs: with kodiPkgs; [
        pvr-hts
      ]))
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
