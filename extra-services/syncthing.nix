{ lib, config, pkgs, ... }:
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

  config = let
    cfg = config.localConfiguration.extraServices.syncthing;
    userConfig = if cfg.user == null then {} else {
      user = cfg.user;
      group = cfg.user;
      dataDir = "/home/${cfg.user}/.syncthing/folders";
      configDir = "/home/${cfg.user}/.syncthing/config";
    };
  in mkIf cfg.enable {

    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
    } // userConfig;

    services.nginx = if cfg.domain == null then {} else {
      enable = true;
      recommendedProxySettings = true;
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
