# PHP-FPM pool for Nextcloud
{lib, config, ...}:
{

  options.services.webapps.nextcloud.socket.fpm = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    user = mkOption {
      type = types.str;
      default = "nextcloud";
    };
    group = mkOption {
      type = types.str;
      default = "nextcloud";
    };
    path = mkOption {
      type = types.path;
    };
  };

  config = let
    instanceConfig = config.services.webapps.nextcloud;
    socketConfig = instanceConfig.socket.fpm;
    enabled = (
      instanceConfig.enable &&
      socketConfig.enable
    );
    socketPath = socketConfig.path;
    socketUser = socketConfig.user;
    socketGroup = socketConfig.group;

    serverConfig = config.services.webapps._nextcloud.server;
    serverUser = serverConfig.user;
    serverGroup = serverConfig.group;

    databaseConfig = config.services.webapps._nextcloud.database;
    databaseService = databaseConfig.service;

    preStart = config.services.webapps._nextcloud.preStart;

    configDir = instanceConfig.directory + "/config";

    poolName = "nextcloud-${instanceConfig.name}";

  in lib.mkIf enabled {

    services.webapps.nextcloud.socket.fpm.path = lib.mkDefault
      "/run/phpfpm/${poolName}.sock";

    # Some Nextcloud internal config
    services.webapps._nextcloud.socket = {
      type = "fastcgi";
      path = socketPath;
      user = socketUser;
      group = socketGroup;
      # The service name is determined by php-fpm given the pool name.
      service = "phpfpm-${poolName}";
      php = config.services.phpfpm.phpPackage;
    };

    # Actual socket configuration
    services.phpfpm.poolConfigs."${poolName}" = ''
      listen = ${socketPath}
      listen.owner = ${serverUser}
      listen.group = ${serverGroup}
      user = ${socketUser}
      group = ${socketGroup}
      pm = ondemand
      pm.max_children = 4
      pm.process_idle_timeout = 10s
      pm.max_requests = 200
      env[NEXTCLOUD_CONFIG_DIR] = "${configDir}"
    '';

    users.extraUsers.nextcloud = {
      group = "nextcloud";
      uid = 666; # config.ids.uids.nextclou;
    };
    users.extraGroups.nextcloud.gid = 666; # config.ids.gids.mysql;

  };

}
