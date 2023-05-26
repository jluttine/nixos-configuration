{ lib, config, pkgs, ... }:
{

  options.services.media = {
    enable = lib.mkEnableOption "Media server with jellyfin";
    domain = lib.mkOption {
      type = lib.types.str;
    };
    ssl = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = let
    cfg = config.services.media;
  in lib.mkIf cfg.enable {

    services.jellyfin.enable = true;

    # Create a group for media files
    users.groups.media = { };
    users.users.jellyfin.extraGroups = [ "media" ];
    systemd.services.jellyfin.serviceConfig = {
      SupplementaryGroups = ["media"];
      # Enable /tmp folder so transcoding can put its files there
      PrivateTmp = true;
    };

    # NOTE: Don't open firewall, use Nginx as reverse proxy.

    # Reverse proxy so we can have domain name and SSL
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = cfg.ssl;
        enableACME = cfg.ssl;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8096/"; # The / is important!
          };
        };
      };
    };

  };

}
