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
    services.webapps.nextcloud.pilvi = {
      package = pkgs.nextcloud;
      server = (import ./nextcloud/vhosts/nginx.nix);
      socket = (import ./nextcloud/sockets/fmp.nix);
      database = (import ./nextcloud/databases/mariadb.nix);
    };
  };

}
