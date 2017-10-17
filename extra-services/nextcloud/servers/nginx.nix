{lib, config, pkgs, ...}:

{

  options.services.webapps.nextcloud.server.nginx = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    vhost = mkOption {
      type = types.str;
    };
    user = mkOption {
      type = types.str;
      default = "nginx";
    };
    group = mkOption {
      type = types.str;
      default = "nginx";
    };
  };

  config = let
    instanceConfig = config.services.webapps.nextcloud;
    serverConfig = instanceConfig.server.nginx;
    enabled = (
      instanceConfig.enable &&
      serverConfig.enable
    );

  in lib.mkIf enabled {

    # Some Nextcloud internal config
    services.webapps._nextcloud.server = {
      user = serverConfig.user;
      group = serverConfig.group;
    };

    # Actual server configuration
    services.nginx = {
      enable = true;

      virtualHosts."${serverConfig.vhost}" = let

        nextcloudPackage = instanceConfig.package;
        nginxPackage = config.services.nginx.package;

        vhost = serverConfig.vhost;

        socketConfig = config.services.webapps._nextcloud.socket;
        socketPath = socketConfig.path;
        socketType = socketConfig.type;

        appsInstalledURL = "apps-installed/";
        appsDir = instanceConfig.directory + "/apps";

        phpConfig = {

          fastcgi = ''
            fastcgi_split_path_info ^(.+\\.php)(/.*)$;
            include ${nginxPackage}/conf/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
            fastcgi_pass unix:${socketPath};
          '';

          # # uwsgi not yet supported
          # uwsgi = ''
          # '';

        }."${socketType}";

      in {
        root = "${nextcloudPackage}";
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
            extraConfig = phpConfig;
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
    };
  };

}
