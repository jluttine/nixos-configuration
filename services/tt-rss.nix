{ lib, config, pkgs, ... }:
{
  config = let
    cfg = config.services.tt-rss;
    virtualHost = cfg.virtualHost;
  in lib.mkIf cfg.enable {

    # Some minor improvements to tt-rss service
    services.tt-rss = {
      selfUrlPath = lib.mkIf (virtualHost != null) (
        lib.mkDefault "https://${virtualHost}/"
      );
    };

    # Use SSL
    services.nginx = lib.mkIf (virtualHost != null) {
      virtualHosts."${virtualHost}" = {
        forceSSL = true;
        enableACME = true;
      };
    };

  };
}
