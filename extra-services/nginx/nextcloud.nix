{ config, pkgs, ... }:
{

  # Group and user IDs for Nextcloud
  users.extraGroups.nextcloud.gid = 300;
  users.extraUsers.nextcloud= {
    #isNormalUser = false;
    group = "nextcloud";
    uid = 300;
  };

  # NOTE: Nextcloud installation by Nix should be kept immutable:
  #
  # - Use config directory outside Nix store (NEXTCLOUD_CONFIG_DIR)
  # - Use data directory outside Nix store
  # - Use apps directory outside Nix store
  # - Disable app store
  #
  # One needs to create the NEXTCLOUD_CONFIG_DIR manually.
  #
  # mkdir -p /var/nextcloud/config
  # mkdir -p /var/nextcloud/data
  # mkdir -p /var/nextcloud/apps
  # chown -R nextcloud:nextcloud /var/nextcloud
  # chmod -R o-rwx /var/nextcloud
  #
  # Edit config.php:
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
      "~* \\.(?:css|js)$" = {
        tryFiles = "$uri /index.php$uri$is_args$args";
      };
      # Other static assets
      "~* \\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$" = {
        tryFiles = "$uri /index.php$uri$is_args$args";
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
