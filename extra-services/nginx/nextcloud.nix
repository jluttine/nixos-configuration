{ config, pkgs, ... }:
{

  # Group and user IDs for Nextcloud
  users.extraGroups.nextcloud.gid = 300;
  users.extraUsers.nextcloud= {
    #isNormalUser = false;
    group = "nextcloud";
    uid = 300;
  };

  # NOTE: Nextcloud installation by Nix should be kept immutable. Thus, the
  # following files/directories need to be writable by Nextcloud, thus they need
  # to be outside Nix store:
  #
  # - config/ (set with NEXTCLOUD_CONFIG_DIR)
  # - data/ (set at first login and datadirectory in config.php)
  # - apps/ (apps_paths in config.php, or disable app store)
  # - assets/ (assetdirectory in config.php)
  # - themes/ (??? how to set?)
  # - mount.json (mount_file in config.php, defaults to /var/www/nextcloud/data/mount.json)
  #
  # One needs to create the NEXTCLOUD_CONFIG_DIR manually.
  #
  # mkdir -p /var/nextcloud/config
  # mkdir -p /var/nextcloud/data
  # mkdir -p /var/nextcloud/apps-local
  # mkdir -p /var/nextcloud/assets
  # chown -R nextcloud:nextcloud /var/nextcloud
  # chmod -R o-rwx /var/nextcloud/config
  # chmod -R o-rwx /var/nextcloud/data
  # TODO/FIXME: The web server (nginx) needs read access to the custom apps dir (apps-local). Either have o+rx or set chgrp to nginx with o-rwx?
  #
  # Edit config.php:
  #
  # alias occ="sudo -u NEXTCLOUD_CONFIG_DIR="/var/www/nextcloud/config" nextcloud ${pkgs.php}/bin/php ${pkgs.nextcloud}/occ"
  #
  # Path configurations:
  # occ config:system:set assetdirectory --value="/var/www/nextcloud/assets"
  # occ config:system:set datadirectory --value="/var/www/nextcloud/data"
  # occ config:system:set mount_file --value="/var/www/nextcloud/data/mount.json"
  # ## OR? occ config:system:set apps_paths 0 path --value='OC::$SERVERROOT."/apps"'
  # occ config:system:set apps_paths 0 path --value="${pkgs.nextcloud}/apps"
  # occ config:system:set apps_paths 0 url --value="/apps"
  # occ config:system:set apps_paths 0 writable --value=false --type=boolean
  # occ config:system:set apps_paths 1 path --value="/var/www/nextcloud/apps-local"'   # use the same dir name as below so no need to rewrite in nginx
  # occ config:system:set apps_paths 1 url --value="/apps-local"   # this is used by nginx to detect assets that are to be served from different web root
  # occ config:system:set apps_paths 1 writable --value=true --type=boolean
  #
  # Database settings:
  # occ config:system:set dbtype --value="mysql"
  # occ config:system:set dbhost --value="localhost"
  # occ config:system:set dbport --value=""
  # occ config:system:set dbname --value="nextcloud"
  # occ config:system:set dbuser --value="nextcloud"
  # occ config:system:set dbpassword --value="password"
  #
  # Trusted domains:
  # occ config:system:set trusted_domains 0 --value="localhost"
  # occ config:system:set trusted_domains 1 --value="mydomain.com"
  #
  # <?php
  # $CONFIG = array (
  #  ...
  #   "apps_paths" => array (
  #     0 => array (
  #       "path"     => OC::$SERVERROOT."/apps",
  #       "url"      => "/apps",
  #       "writable" => false,
  #     ),
  #     1 => array (
  #       "path"     => "/var/nextcloud/apps",
  #       "url"      => "/apps-custom",
  #       "writable" => true,
  #     ),
  #   ),
  #   ...
  # );
  #
  # Or, disable app store in config.php:
  #
  # <?php
  # $CONFIG = array (
  #   ...
  #   'appstoreenabled' => false,
  #   ..
  # );

  # Option I: PHP-FPM pool for Nextcloud
  services.phpfpm.poolConfigs = let 
    phpfpmSocketName = "/run/phpfpm/nextcloud.sock";
    phpfpmUser = "nextcloud";
    phpfpmGroup = "nextcloud";
    server = "nginx";
  in
  {
    nextcloud = ''
      listen = ${phpfpmSocketName}
      listen.owner = ${server}
      listen.group = ${server}
      user = ${phpfpmUser}
      group = ${phpfpmGroup}
      pm = ondemand
      pm.max_children = 4
      pm.process_idle_timeout = 10s
      pm.max_requests = 200
      env[NEXTCLOUD_CONFIG_DIR] = "/var/nextcloud/config"
    '';
  };

  # Option II: uWSGI for Nextcloud
  services.uwsgi = {
    enable = true;
    user = "uwsgi";
    group = "uwsgi";
    # PHP plugin not working at the moment. See: https://github.com/NixOS/nixpkgs/issues/24357
    #plugins = [ "php" ];
    # Emperor instance
    instance = {
      type = "emperor";
      vassals = {
        nextcloud = {
          type = "normal";
          uid = "nextcloud";
          gid = "nextcloud";
          socket = "/run/uwsgi/nextcloud.sock";
          # Run with at least 1 process but increase up to 4 when needed
          cheaper = 1;
          processes = 4;
          php-docroot = "${pkgs.nextcloud}";
        };
      };
    };
  };

  # Virtual host settings
  services.nginx.virtualHosts."pilvi.fi" = {
    serverName = "pilvi.fi";
    root = "${pkgs.nextcloud}";
    default = true;
    # FIXME: Enable (and force) SSL
    enableSSL = false;
    forceSSL = false;
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
          fastcgi_pass unix:/run/phpfpm/nextcloud.sock;
        '';
      };
      # CSS and JavaScript files
      "~* ^/(?!apps-local).*\\.(?:css|js)$" = {
        tryFiles = "$uri /index.php$uri$is_args$args";
      };
      # Other static assets
      "~* ^/(?!apps-local).*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$" = {
        tryFiles = "$uri /index.php$uri$is_args$args";
      };
      # Locally installed apps:
      #
      # No need to specify location for PHP files of installed apps???
      #
      # CSS and JavaScript files for installed apps
      "~* ^/apps-local/.*\\.(?:css|js)$" = {
        root = "/var/nextcloud";
        tryFiles = "$uri =404";
      };
      # Other static assets for installed apps
      "~* ^/apps-local/.*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$" = {
        root = "/var/nextcloud";
        tryFiles = "$uri =404";
      };
      "~ ^/(?:build|tests|config|lib|3rdparty|templates|data|\\.|autotest|occ|issue|indie|db_|console)" = {
        extraConfig = "deny all;"; 
      };
    };
  };

  # Database settings
  services.mysql = {
    enable = true;
    #package = pkgs.mysql57;
    # Can I just use MariaDB like this?
    package = pkgs.mariadb;
    #dataDir = "/var/db/mysql";
    initialDatabases = [
      # Or use writeText instead of literalExample?
      #{ name = "nextcloud"; schema = literalExample "./nextcloud.sql"; }
      {
        name = "nextcloud";
        schema = pkgs.writeText "nextcloud.sql"
        ''
        create user if not exists 'nextcloud'@'localhost' identified by 'password';
        grant all privileges on nextcloud.* to 'nextcloud'@'localhost' identified by 'password';
        '';
      }
    ];
    #initialScript = pkgs.writeText "nextcloud.sql" 
    #''
    #create user if not exists 'nextcloud'@'localhost' identified by 'password';
    #grant all privileges on nextcloud.* to 'nextcloud'@'localhost' identified by 'password';
    #'';
  };

  # Nextcloud package
  environment.systemPackages = with pkgs; [
    nextcloud
  ];

}
