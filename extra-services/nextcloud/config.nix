{name, config}:
let
  # configWithName = config // {name=name;};
  # serverConfig = config.server configWithName;
  # socketConfig = config.socket configWithName;
  # databaseConfig = config.database configWithName;
  # nextcloudConfig = {
  #   services.webapps.nextcloud."$name" = (
  #     serverConfig.nextcloudConfig //
  #     socketConfig.nextcloudConfig //
  #     databaseConfig.nextcloudConfig
  #   );
  # };
in
(
  { }
  # serverConfig.globalConfig //
  # socketConfig.globalConfig //
  # databaseConfig.globalConfig
  # // nextcloudConfig
)
