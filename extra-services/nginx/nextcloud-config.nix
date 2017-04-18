{ cfg, pkgs, lib, globalConfig }:

with lib;

let

  # Directories
  configDir = "${cfg.path}/config";
  dataDir = "${cfg.path}/data";
  appsDir = "${cfg.path}/apps";
  assetsDir = "${cfg.path}/assets";
  scriptsDir = "${cfg.path}/scripts";

  configFile = "${configDir}/config.php";

  socket = "/run/phpfpm/nextcloud.sock";

  appsInternalURL = "apps";
  appsInstalledURL = "apps-installed";

  nextcloudScripts = pkgs.runCommand "nextcloud-scripts"
    { buildInputs = [ pkgs.makeWrapper ]; }
    ''
      mkdir -p $out/bin
      makeWrapper                                       \
        ${pkgs.sudo}/bin/sudo                           \
	$out/bin/nextcloud-occ                          \
        --add-flags "-u ${cfg.phpUser}"                 \
        --add-flags "NEXTCLOUD_CONFIG_DIR=${configDir}" \
        --add-flags ${cfg.phpPackage}/bin/php           \
	--add-flags ${cfg.package}/occ
      makeWrapper                                              \
        ${globalConfig.services.mysql.package}/bin/mysql       \
	$out/bin/nextcloud-deleteDatabase                      \
        --add-flags "-Bse"                                     \
	--add-flags '"drop database if exists ${cfg.dbName};"'
    '';



  #
  # Script for creating the database, creating the user and setting privileges
  #
  # TODO/FIXME: You need to revoke all existing privileges just in case the user
  # changes dbUser so that the privileges for the old dbUser are removed.
  # However, I don't know how to do it. The following didn't work:
  #
  #   revoke all privileges on ${cfg.dbName}.* from '%'@'%';
  #
  # TODO/FIXME: Password will be in plain text in nix store.
  #
  dbScript = pkgs.writeText "${cfg.dbName}.sql" ''
    create database if not exists ${cfg.dbName};
    create user if not exists '${cfg.dbUser}'@'localhost' identified by '${cfg.dbPassword}';
    grant all privileges on ${cfg.dbName}.* to '${cfg.dbUser}'@'localhost' identified by '${cfg.dbPassword}';
  '';

  #
  # Nextcloud installation will fail if there is no writable apps path. This
  # cannot be given as a flag to the installer but must be configured in
  # config.php. Thus, we need to have a simple config.php specifying apps paths
  # properly before installing Nextcloud.
  #
  preinstallConfigFile = pkgs.writeText "nextcloud-config.php" ''
    <?php
    $CONFIG = array (
      'installed' => false,
      'apps_paths' =>
      array (
        0 =>
        array (
          'path' => '${cfg.package}/apps',
          'url' => '/${appsInternalURL}',
          'writable' => false,
        ),
        1 =>
        array (
          'path' => '${appsDir}',
          'url' => '/${appsInstalledURL}',
          'writable' => true,
        ),
      ),
    );
  '';

  # NOTE: Nextcloud has a console client occ which can be used to install and
  # upgrade a Nextcloud instance and modify its settings config.php. However:
  #
  # - If Nextcloud has already been installed, installation script fails because
  #   the admin user already exists. Thus, the installation script cannot be
  #   used for already installed Nextcloud instances.
  #
  # - If apps directory isn't writable (apps directory in nix store),
  #   installation fails. The console client could be used to set a different
  #   apps directory which is writable but this is possible only after
  #   installation. Thus, this setting must be written to config.php without the
  #   help of occ.
  #
  # No config.php:
  #
  # -> occ fails because apps directory isn't writable
  #
  # installed=false in config.php and not installed to database:
  #
  # -> occ installation succeeds
  #
  # installed=false in config.php but has been installed to database:
  #
  # -> occ installation fails because username is already being used
  #
  #
  # Conclusion:
  #
  # Installation script: Checks that config.php doesn't exist and writes a
  # minimal example for it. Then, runs installation if not yet installed.
  #
  # If config.php exists, assume that Nextcloud has been installed. Otherwise
  # it's the user's problem to sort things out.
  #
  # Run configuration script after installation and as service prestart script
  # if config.php exists.

  # Nextcloud console for configuring Nextcloud

  mutableConfiguration = ''
    # Configure directories
    occ config:system:set assetdirectory --value="${assetsDir}"
    occ config:system:set datadirectory --value="${dataDir}"
    occ config:system:set apps_paths 0 path --value="${cfg.package}/apps"
    occ config:system:set apps_paths 0 url --value="/${appsInternalURL}"
    occ config:system:set apps_paths 0 writable --value=false --type=boolean
    occ config:system:set apps_paths 1 path --value="${appsDir}"
    occ config:system:set apps_paths 1 url --value="/${appsInstalledURL}"
    occ config:system:set apps_paths 1 writable --value=true --type=boolean

    # Configure database
    occ config:system:set dbtype --value="${cfg.dbType}"
    occ config:system:set dbname --value="${cfg.dbName}"
    occ config:system:set dbuser --value="${cfg.dbUser}"
    occ config:system:set dbpassword --value="${cfg.dbPassword}"

  '';

  immutableConfiguration = ''

    # Read some config values so they are kept unmodified
    INSTANCEID=`occ config:system:get instanceid | tail -n 1`
    PASSWORDSALT=`occ config:system:get passwordsalt | tail -n 1`
    SECRET=`occ config:system:get secret | tail -n 1`
    VERSION=`occ config:system:get version | tail -n 1`

    # Delete old configuration. After this, occ command doesn't work because
    # there's no config.php. FIXME: Should the old file be backed up?
    rm ${configFile}
    touch ${configFile}
    chown ${cfg.phpUser} ${configFile}
    chgrp ${cfg.phpGroup} ${configFile}
    chmod 640 ${configFile}

    # Set the configuration and keep some of the existing configuration. Note
    # that the version is set to the version number of the existing Nextcloud
    # instance so that `occ upgrade` knows from which version it is actually
    # starting the upgrade.
    echo "<?php
    \$CONFIG = array (
      'installed' => true,
      'apps_paths' =>
      array (
        0 =>
        array (
          'path' => '${cfg.package}/apps',
          'url' => '/${appsInternalURL}',
          'writable' => false,
        ),
        1 =>
        array (
          'path' => '${appsDir}',
          'url' => '/${appsInstalledURL}',
          'writable' => true,
        ),
      ),
      'passwordsalt' => '$PASSWORDSALT',
      'secret' => '$SECRET',
      'trusted_domains' =>
      array (
        0 => 'localhost',
      ),
      'datadirectory' => '${dataDir}',
      'overwrite.cli.url' => 'http://localhost',
      'dbtype' => '${cfg.dbType}',
      'version' => '$VERSION',
      'dbname' => '${cfg.dbName}',
      'dbhost' => 'localhost',
      'dbtableprefix' => 'oc_',
      'dbuser' => '${cfg.dbUser}',
      'dbpassword' => '${cfg.dbPassword}',
      'logtimezone' => 'UTC',
      'instanceid' => '$INSTANCEID',
    );
    " > ${configFile}
  '';

  # TODO/FIXME: The startup script will be readable from nix store by any user.
  # Passwords in plain text. Need to use some encryption. See:
  # https://github.com/NixOS/nix/issues/8
  startupScript = ''

    set -e

    #
    # Set up the database
    #
    ${globalConfig.services.mysql.package}/bin/mysql < "${dbScript}"

    #
    # Create directories with correct permissions
    #
    mkdir -p ${configDir}
    mkdir -p ${dataDir}
    mkdir -p ${appsDir}
    mkdir -p ${assetsDir}
    chmod 750 ${configDir}
    chmod 750 ${dataDir}
    chmod 750 ${appsDir}
    chmod 750 ${assetsDir}
    chown -R ${cfg.phpUser}:${cfg.phpGroup} ${configDir}
    chown -R ${cfg.phpUser}:${cfg.phpGroup} ${dataDir}
    chown -R ${cfg.phpUser}:${cfg.serverConfig.group} ${appsDir}
    chown -R ${cfg.phpUser}:${cfg.serverConfig.group} ${assetsDir}

    function ncsudo {
      ${pkgs.sudo}/bin/sudo -u ${cfg.phpUser} "$@"
    }

    function occ {
      ncsudo NEXTCLOUD_CONFIG_DIR=${configDir} OC_PASS="${cfg.adminPassword}" ${cfg.phpPackage}/bin/php ${cfg.package}/occ "$@"
    }

    #
    # IMPORTANT NOTICE
    #
    # If the user changes `cfg.path` for an already installed Nextcloud, the
    # installer is run because no existing config file was found. However, the
    # installation will most likely fail because stuff already exists in the
    # database but the installer tries to create database tables. This requires
    # manual work from the user: the old path must be moved to the new path,
    # otherwise all `data`, `config` and other mutable directories will remain
    # in the old location and they are not found nor used by the newly
    # configured instance. Thus, it is strongly recommended NOT to change
    # `path` after the Nextcloud instance has been installed.  Perhaps, we
    # should generate a helper script `nextcloud-movePath` which would just
    # move the current `cfg.path` to a new given location and then the user can
    # change the value in nix configuration?
    #
    # If the user changes the database type or name, access to the current
    # Nextcloud database is lost. Thus, it is strongly recommended NOT to change
    # `dbType` nor `dbName` after the Nextcloud instance has been installed.
    # Perhaps, we should generate a helper script `nextcloud-databaseChange` and
    # `nextcloud-databaseRename` to help the user with those tasks? After using
    # those, the user should make changes to the nix configuration. `occ
    # db:convert-type` can be used to convert from one DB type to another but
    # not within the same type. Use DB type specific renaming for that.
    #
    if [ ! -e ${configDir}/config.php ] ; then
      # If config.php doesn't exist:
      #
      # Create simple config.php
      cp ${preinstallConfigFile} ${configFile}
      chown ${cfg.phpUser} ${configFile}
      chgrp ${cfg.phpGroup} ${configFile}
      chmod 640 ${configFile}
      # Install Nextcloud instance
      # See: https://docs.nextcloud.com/server/9/admin_manual/configuration_server/occ_command.html#command-line-installation-label
      occ maintenance:install               \
        --database "${cfg.dbType}"          \
        --database-name "${cfg.dbName}"     \
        --database-user "${cfg.dbUser}"     \
        --database-pass "${cfg.dbPassword}" \
        --admin-user="${cfg.adminUser}"     \
        --admin-pass="${cfg.adminPassword}" \
        --data-dir "${dataDir}"             \
        --no-interaction                    \
	|| exit 1
    fi

    # Assert the state of the Nextcloud instance. If this check failed, the
    # other operations could mess up config.php. Thus, better to fail and
    # let the user make appropriate fixes to the system manually. This step
    # fails at least in the following scenarios when config.php already existed
    # and thus installation was skipped:
    #
    # - Installed according to config.php but not in the database, thus occ
    #   throws an exception as it tries to access the database. This state is
    #   possible if the user has changed database type or name in the nix
    #   configuration.
    #
    # - Not installed according to config.php. In that case, `occ
    #   config:system:get` is not available and occ fails because of that. This
    #   state shouldn't be possible with this nix module.
    if [ `occ config:system:get installed` != "true" ] ; then
      exit 1
    fi

    # TODO: It would be possible to read some current configuration and make some
    # extra steps with occ based on that so the configurations can be done on
    # Nix-side. For instance, manage users by adding/removing users, converting
    # from DB to another etc. However, it's probably best to only manage
    # the contents of config.php (and the admin user) with nix.

    #
    # For immutability, remove config.php and write it from scratch. Is this
    # what we want? With this approach, the user (nor Nextcloud itself)
    # shouldn't modify config.php because those changes will be erased at each
    # upgrade. It is possible not to remove old config.php and just make those
    # changes with occ that are maintained by the nix configuration. This would
    # leave other configurations untouched.  Perhaps there could be an option
    # for that? cfg.mutableConfig = true?
    #

    ${immutableConfiguration}

    # Configure admin account. This mutates the database, not config.php. NOTE:
    # If admin username is changed, the old username and its admin privileges
    # aren't removed. This is account modification is done here because the
    # installation needs to create the admin account so it needs to be specified
    # in nix configuration and thus it needs to be specified even if not
    # installing just to keep the Nextcloud instance consistent with the nix
    # configuration.
    occ user:info ${cfg.adminUser} || occ user:add --password-from-env --no-interaction ${cfg.adminUser}
    occ user:resetpassword --password-from-env --no-interaction ${cfg.adminUser}
    occ group:adduser admin ${cfg.adminUser}

    # Upgrade Nextcloud instance.
    # See: https://docs.nextcloud.com/server/9/admin_manual/configuration_server/occ_command.html#command-line-upgrade-label
    #
    # This has to be run after writing config.php just in case settings (e.g.,
    # database) has been changed and the system accordingly.
    occ upgrade

  '';

in
mkIf cfg.enable {

  #
  # Group and user IDs for Nextcloud
  # TODO/FIXME: These should be set elsewhere.
  #
  users.extraGroups.nextcloud.gid = 300;
  users.extraUsers.nextcloud= {
    #isNormalUser = false;
    group = "nextcloud";
    uid = 300;
  };

  # Option I: PHP-FPM pool for Nextcloud
  services.phpfpm.poolConfigs.nextcloud = ''
    listen = ${socket}
    listen.owner = ${cfg.serverConfig.user}
    listen.group = ${cfg.serverConfig.group}
    user = ${cfg.phpUser}
    group = ${cfg.phpGroup}
    pm = ondemand
    pm.max_children = 4
    pm.process_idle_timeout = 10s
    pm.max_requests = 200
    env[NEXTCLOUD_CONFIG_DIR] = "${configDir}"
  '';
  systemd.services.phpfpm-nextcloud = {
    after = [ "mysql.service" ];
    preStart = startupScript;
  };

#  # Option II: uWSGI for Nextcloud
#  services.uwsgi = {
#    enable = true;
#    user = "uwsgi";
#    group = "uwsgi";
#    # PHP plugin not working at the moment. See: https://github.com/NixOS/nixpkgs/issues/24357
#    #plugins = [ "php" ];
#    # Emperor instance
#    instance = {
#      type = "emperor";
#      vassals = {
#        nextcloud = {
#          # PHP plugin not working at the moment. See: https://github.com/NixOS/nixpkgs/issues/24357
#          #plugins = [ "php" ];
#          type = "normal";
#          uid = "nextcloud";
#          gid = "nextcloud";
#          socket = "/run/uwsgi/nextcloud.sock";
#          # Run with at least 1 process but increase up to 4 when needed
#          cheaper = 1;
#          processes = 4;
#          php-docroot = "${pkgs.nextcloud}";
#        };
#      };
#    };
#  };

  # Virtual host settings. (Nginx assumed..)
  #services."${cfg.serverConfig.server}".virtualHosts."${cfg.serverConfig.vhost}" = {
  services.nginx.virtualHosts."${cfg.serverConfig.vhost}" = {
    root = "${cfg.package}";
    extraConfig = ''
      client_max_body_size 1024M;
      gzip off;
      error_page 403 /core/templates/403.php;
      error_page 404 /core/templates/404.php;
    '';
    # NOTE: Don't rely on the order of the locations!
    locations = {
      "/robots.txt" = {
        extraConfig = "allow all;";
      };
      "/.well-known/carddav" = {
        extraConfig = "return 301 $scheme://$host/remote.php/dav;";
      };
      "/.well-known/caldav" = {
        extraConfig = "return 301 $scheme://$host/remote.php/dav;";
      };
      # Root
      "/" = {
        extraConfig = ''
          rewrite ^ /index.php$uri;
        '';
      };
      # PHP files
      "~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\\.php(?:$|/)" = {
        extraConfig = ''
          fastcgi_split_path_info ^(.+\\.php)(/.*)$;
          include ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_param PATH_INFO $fastcgi_path_info;
          fastcgi_pass unix:${socket};
        '';
      };
      # CSS and JavaScript files
      "~* ^/(?!${appsInstalledURL}).*\\.(?:css|js)$" = {
        tryFiles = "$uri /index.php$uri$is_args$args";
      };
      # Other static assets
      "~* ^/(?!${appsInstalledURL}).*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$" = {
        tryFiles = "$uri /index.php$uri$is_args$args";
      };
      # Locally installed apps:
      #
      # No need to specify location for PHP files of installed apps???
      #
      # CSS and JavaScript files for installed apps
      "~* ^/${appsInstalledURL}/(.*\\.(?:css|js))$" = {
        root = "${appsDir}";
        tryFiles = "/$1 =404";
      };
      # Other static assets for installed apps
      "~* ^/${appsInstalledURL}/(.*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg))$" = {
        root = "${appsDir}";
        tryFiles = "/$1 =404";
      };
      # Some hidden files
      "~ ^/(?:build|tests|config|lib|3rdparty|templates|data|\\.|autotest|occ|issue|indie|db_|console)" = {
        extraConfig = "deny all;";
      };
    };
  };

  # Database settings
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    initialDatabases = [
      # Or use writeText instead of literalExample?
      {
        name = "${cfg.dbName}";
	# TODO/FIXME: Drop privileges for all other users so old user account privileges will be erased.
        schema = pkgs.writeText "${cfg.dbName}.sql" ''
          create user if not exists '${cfg.dbUser}'@'localhost' identified by '${cfg.dbPassword}';
          grant all privileges on ${cfg.dbName}.* to '${cfg.dbUser}'@'localhost' identified by '${cfg.dbPassword}';
        '';
      }
    ];
  };

  # Nextcloud package
  environment.systemPackages = [ cfg.package cfg.phpPackage pkgs.sudo nextcloudScripts ];

}
