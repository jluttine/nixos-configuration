{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.rss = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    domain = mkOption {
      type = types.str;
    };
  };

  config = let
    cfg = config.localConfiguration.extraServices.rss;
  in mkIf cfg.enable {

    # Set up Tiny Tiny RSS server
    services.tt-rss = {
      enable = true;
      virtualHost = cfg.domain;
      selfUrlPath = "https://${cfg.domain}/";
      database = {
        type = "mysql";
      };
    };

    # Use SSL
    services.nginx = {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = cfg.ssl;
        enableACME = cfg.ssl;
      };
    };

  };

}
