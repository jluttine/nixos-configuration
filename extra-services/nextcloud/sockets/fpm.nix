# PHP-FPM pool for Nextcloud
#{name, socketConfig}:
{lib, config, name, instanceConfig, ...}:
# let
#   socketPath = "/run/phpfpm/${name}.sock";
#   user = "nextcloud";
#   group = "nextcloud";
# in
# let
#   name = instanceConfig.name;
# in
{

  options = with lib; {
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
      default = "/run/phpfpm/${name}.sock";
    };
    type = mkOption {
      type = types.str;
      default = "fastcgi";
    };
  };

  # # Internal arguments
  # type = "fastcgi";
  # path = socketConfig.path;

  #phpfpm = {serverUser, serverGroup, ...}: {
  phpfpm = let
    socketPath = instanceConfig.socketConfig.path;
    socketUser = instanceConfig.socketConfig.user;
    socketGroup = instanceConfig.socketConfig.group;
    serverUser = instanceConfig.serverConfig.user;
    serverGroup = instanceConfig.serverConfig.group;
    # TODO:
    #configDir = instanceConfig.configDir;
    configDir = "";
  in {
    poolConfigs = {
      "${name}" = ''
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
    };
  };
}
