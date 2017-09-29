# PHP-FPM pool for Nextcloud
{nextcloudConfig}:
let
  cfg = nextcloudConfig;
  socketPath = "/run/phpfpm/${cfg.name}.sock";
  user = "nextcloud";
  group = "nextcloud";
in
{

  nextcloudConfig = {
    socket = {
      type = "fpm";
      path = socketPath;
      # user = user;
      # group = group;
    };
  };

  globalConfig = {
    services.phpfpm.poolConfigs = let
    in
    {
      "${name}" = ''
        listen = ${socketPath}
        listen.owner = ${cfg.server.user}
        listen.group = ${cfg.server.group}
        user = ${user}
        group = ${group}
        pm = ondemand
        pm.max_children = 4
        pm.process_idle_timeout = 10s
        pm.max_requests = 200
        env[NEXTCLOUD_CONFIG_DIR] = "${cfg.configDir}"
      '';
    };
  };
}
