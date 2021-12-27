{ lib, config, pkgs, ... }:
{

  # Add a few options to the existing radicale service
  options.services.radicale = {
    ssl = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    virtualHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    htpasswd = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = let
    cfg = config.services.radicale;
    htpasswdFile = pkgs.writeText "radicale-passwords" cfg.htpasswd;
  in lib.mkIf cfg.enable {

    services.radicale.settings = {
      auth = lib.mkIf (cfg.htpasswd != null) {
        type = "htpasswd";
        htpasswd_filename = "${htpasswdFile}";
        htpasswd_encryption = "bcrypt";
        delay = "1";
      };
    };

    # Reverse proxy so we can have domain name and SSL
    services.nginx = lib.mkIf (cfg.virtualHost != null) {
      enable = true;
      virtualHosts."${cfg.virtualHost}" = {
        forceSSL = cfg.ssl;
        enableACME = cfg.ssl;
        locations = {
          "/" = {
            proxyPass = "http://localhost:5232/"; # The / is important!
            extraConfig = ''
              proxy_pass_header Authorization;
            '';
          };
        };
      };
    };

  };

}
