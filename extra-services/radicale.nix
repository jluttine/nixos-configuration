{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.radicale = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    ssl = mkOption {
      type = types.bool;
      default = true;
    };
    domain = mkOption {
      type = types.str;
    };
  };

  config = let
    cfg = config.localConfiguration.extraServices.radicale;
    # Create/modify htpasswd file in this directory with:
    # htpasswd -B radicale-passwords username
    htpasswd = readFile ./radicale-passwords;
    htpasswdFile = pkgs.writeText "radicale-passwords" htpasswd;
  in mkIf cfg.enable {

    services.radicale = {
      enable = true;
      config = ''
      [auth]
      type = htpasswd
      htpasswd_filename = ${htpasswdFile}
      htpasswd_encryption = bcrypt
      delay = 1
      '';
    };

    networking.firewall.allowedTCPPorts = [80 443];

    # Reverse proxy so we can have domain name and SSL
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.domain}" = {
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
