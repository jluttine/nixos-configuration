{lib, pkgs, config, ...}:

{

  options.services.webapps.nextcloud.database.mysql = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    name = mkOption {
      type = types.str;
    };
  };

  # Database settings
  config = let
    instanceConfig = config.services.webapps.nextcloud;
    databaseConfig = instanceConfig.database.mysql;
    enabled = (
      instanceConfig.enable &&
      databaseConfig.enable
    );

    name = databaseConfig.name;

    socketUser = config.services.webapps._nextcloud.socket.user;

  in lib.mkIf enabled {

    services.webapps.nextcloud.database.mysql.name = lib.mkDefault
      "nextcloud_${instanceConfig.name}";

    # Internal Nextcloud configuration
    services.webapps._nextcloud.database = {
      type = "mysql";
      name = databaseConfig.name;
      host = "localhost:/run/mysqld/mysqld.sock";
      service = "mysql.service";
    };

    # Actual database configuration
    services.mysql = {
      enable = true;
      ensureDatabases = [name];
      ensureUsers = [
        {
          name = socketUser;
          ensurePermissions = {
            "${name}.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };
  };
}
