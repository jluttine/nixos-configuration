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
      name = "foobar";
      #server.nginx = {};
      socket.fpm = {};
      #package = pkgs.nextcloud;
      # server = (import ./nextcloud/vhosts/nginx.nix);
      # socket = (import ./nextcloud/sockets/fpm.nix);
      # serverConfig = {
      #   vhost = "pilvi.fi";
      # };
      #database = (import ./nextcloud/databases/mariadb.nix);
    };
  };

}
