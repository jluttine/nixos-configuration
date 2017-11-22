{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.syncthing = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config.services = let
    cfg = config.localConfiguration.extraServices.syncthing;
    userConfig = if cfg.user == null then {} else {
      user = cfg.user;
      group = cfg.user;
      dataDir = "/home/${cfg.user}/.syncthing/config";
    };
  in mkIf cfg.enable {

    syncthing = {
      enable = true;
      openDefaultPorts = true;
    } // userConfig;

    nginx = if cfg.domain == null then {} else {
      enable = true;
      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8384/";
          };
        };
      };
    };

  };

}
