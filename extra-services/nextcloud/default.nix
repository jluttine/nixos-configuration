{ lib, pkgs, config, ... }:

with lib;

let

  cfg = config.services.webapps.nextcloud;
  configDir = cfg.directory + "/config";
  dataDir = cfg.directory + "/data";
  appsDir = cfg.directory + "/apps";
  assetsDir = cfg.directory + "/assets";

  configFile = cfg.directory + "/config/nixos.config.php";
  mutableConfigFile = cfg.directory + "/config/config.php";
  package = cfg.package;

  internalConfig = config.services.webapps._nextcloud;

  socketUser = internalConfig.socket.user;
  socketGroup = internalConfig.socket.group;
  phpPackage = internalConfig.socket.php;

  serverUser = internalConfig.server.user;
  serverGroup = internalConfig.server.group;

  dbType = internalConfig.database.type;
  dbName = internalConfig.database.name;
  dbHost = internalConfig.database.host;

  boolToString = x: if x then "true" else "false";

  # Map list of app path configurations to strings that are written into
  # config.php.
  #concat = lib.foldl (a: b: a + b) "";
  appsPathsString = lib.concatStrings (
    lib.imap0 (
      index: {path, url, writable, ...}: ''
        ${toString index} =>
        array (
          'path' => '${path}',
          'url' => '${url}',
          'writable' => ${boolToString writable},
        ),
      ''
    ) internalConfig.appsPaths
  );

  occ = pkgs.writeScriptBin "occ" ''
    #!${pkgs.stdenv.shell}
    ${pkgs.sudo}/bin/sudo -u ${socketUser}      \
      NEXTCLOUD_CONFIG_DIR=${configDir}         \
      ${phpPackage}/bin/php ${package}/occ "$@"
  '';

  startup = ''

    set -e

    #
    # Set up directories with correct permissions
    #
    mkdir -p ${configDir}
    mkdir -p ${dataDir}
    mkdir -p ${appsDir}
    mkdir -p ${assetsDir}
    chmod 750 ${configDir}
    chmod 750 ${dataDir}
    chmod 750 ${appsDir}
    chmod 750 ${assetsDir}
    chown -R ${socketUser}:${socketGroup} ${configDir}
    chown -R ${socketUser}:${socketGroup} ${dataDir}
    chown -R ${socketUser}:${serverGroup} ${appsDir}
    chown -R ${socketUser}:${serverGroup} ${assetsDir}
    chown root:${socketGroup} ${configFile}

    #
    # Write the immutable nixos.config.php. Nextcloud will keep mutable
    # configuration in config.php.
    #
    echo "<?php
    \$CONFIG = array (
      'apps_paths' =>
      array (
      ${appsPathsString}
      ),
      'trusted_domains' =>
      array (
        0 => 'localhost',
      ),
      'datadirectory' => '${dataDir}',
      'assetdirectory' => '${assetsDir}',
      'overwrite.cli.url' => 'http://localhost',
      'appstoreenabled' => ${boolToString cfg.appStoreEnabled},
      'dbtype' => '${dbType}',
      'dbname' => '${dbName}',
      'dbhost' => '${dbHost}',
    );
    " > ${configFile}

    #
    # Does the following work when config.php claims that Nextcloud has been
    # installed but it's not in the database? For instance, user has changed
    # database settings in nix configuration.
    #
    installed=`${occ}/bin/occ status  | grep -E -o 'installed: (false|true)' | grep -E -o '(false|true)'`

    if [ $installed == "false" ] ; then
      ${occ}/bin/occ maintenance:install           \
        --database "${dbType}"                     \
        --database-host "${dbHost}"                \
        --database-name "${dbName}"                \
        --database-user "${socketUser}"            \
        --data-dir "${dataDir}"                    \
        --admin-user="${cfg.initialAdminUser}"     \
        --admin-pass="${cfg.initialAdminPassword}" \
        --no-interaction
    fi

    #
    # Upgrade Nextcloud instance.
    #
    ${occ}/bin/occ upgrade
  '';

in {

  imports = [
    # Built-in socket options
    ./sockets/fpm.nix
    # Built-in server options
    ./servers/nginx.nix
    # Built-in database options
    ./databases/mysql.nix
  ];

  options.services.webapps = {

    # User configuration
    nextcloud = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.nextcloud;
      };
      directory = mkOption {
        type = types.path;
        default = "/var/lib/nextcloud";
      };
      initialAdminUser = mkOption {
        type = types.str;
        default = "admin";
      };
      initialAdminPassword = mkOption {
        type = types.str;
        default = "password";
      };
      apps = mkOption {
        type = types.listOf types.package;
        default = [];
      };
      appStoreEnabled = mkOption {
        type = types.bool;
        default = true;
      };
    };

    # Internal configuration for communication between different modules
    _nextcloud = {
      appsPaths = mkOption {
        type = types.listOf (
          types.submodule (
            {name, ...}: {
              options = {
                path = mkOption {
                  type = types.path;
                };
                url = mkOption {
                  type = types.str;
                };
                writable = mkOption {
                  type = types.bool;
                };
              };
            }
          )
        );
      };
      socket = {
        path = mkOption {
          type = types.path;
        };
        type = mkOption {
          type = types.str;
        };
        user = mkOption {
          type = types.str;
        };
        group = mkOption {
          type = types.str;
        };
        service = mkOption {
          type = types.str;
        };
        php = mkOption {
          type = types.package;
        };
      };
      server = {
        user = mkOption {
          type = types.str;
        };
        group = mkOption {
          type = types.str;
        };
      };
      database = {
        type = mkOption {
          type = types.str;
        };
        name = mkOption {
          type = types.str;
        };
        host = mkOption {
          type = types.str;
        };
        service = mkOption {
          type = types.str;
        };
      };
    };

  };

  # Generic configuration of Nextcloud. Sockets, web servers and databases are
  # configured in separate modules.
  config = mkIf config.services.webapps.nextcloud.enable {

    services.webapps._nextcloud.appsPaths = let
      builtinApps = [
        {
          path = "${package}/apps";
          url = "/apps";
          writable = false;
        }
      ];
      storeApps = lib.optionals cfg.appStoreEnabled [
        {
          path = "${appsDir}";
          url = "/apps-store";
          writable = true;
        }
      ];
      extraApps = [];
    in builtinApps ++ storeApps ++ extraApps;

    systemd.services = let
      databaseService = config.services.webapps._nextcloud.database.service;
      socketService = config.services.webapps._nextcloud.socket.service;
    in {
      "${socketService}" = {
        after = [ databaseService ];
        preStart = startup;
      };

    };

    environment.systemPackages = [ occ ];

  };

}
