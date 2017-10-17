{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.pilvi = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.pilvi {
    services.webapps.nextcloud = {
      enable = true;
      server.nginx = {
        enable = true;
        vhost = "cloud.com";
      };
      database.mysql = {
        enable = true;
      };
      socket.fpm = {
        enable = true;
      };
    };
    services.mysql.package = pkgs.mariadb;
  };

}
