{lib, config, instanceConfig, ...}:

let

  instanceOptions = with lib; {
    user = mkOption {
      type = types.str;
      default = "nginx";
    };
    group = mkOption {
      type = types.str;
      default = "nginx";
    };
    vhost = mkOption {
      type = types.str;
    };
  };

  instanceConfig = name: cfg: {
    name = cfg.vhost;
    value = let
      nextcloudConfig = config.services.webapps.nextcloud."${name}";
      nginxPackage = config.services.nginx.package;
      nextcloudPackage = nextcloudConfig.package;
      socketPath = nextcloudConfig.socketConfig.path;
      socketType = nextcloudConfig.socketConfig.type;
      vhost = nextcloudConfig.serverConfig.vhost;

      # TODO:
      appsInstalledURL = "";
      appsDir = "";

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

    in
    {
      value = {
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
in
{

  options.services.webapps.nextcloud.vhosts.nginx = with lib; mkOption {
    type = types.attrsOf (types.submodule instanceOptions);
    default = {};
  };

  config.services.nginx.virtualHosts = (
    mapAttrs'
    instanceConfig
    config.services.webapps.nextcloud.vhosts.nginx
  );

  # # user = "nginx";
  # # group = "nginx";

  # # nginx = {socketPath, socketType, nextcloudPackage, globalConfig}:
  # nginx =
  # let

  #   nginxPackage = config.services.nginx.package;
  #   nextcloudPackage = instanceConfig.package;
  #   socketPath = instanceConfig.socketConfig.path;
  #   socketType = instanceConfig.socketConfig.type;
  #   vhost = instanceConfig.serverConfig.vhost;

  #   # TODO:
  #   appsInstalledURL = "";
  #   appsDir = "";

  #   phpConfig = {

  #     fastcgi = ''
  #       fastcgi_split_path_info ^(.+\\.php)(/.*)$;
  #       include ${nginxPackage}/conf/fastcgi_params;
  #       fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
  #       fastcgi_param PATH_INFO $fastcgi_path_info;
  #       fastcgi_pass unix:${socketPath};
  #     '';

  #     # # uwsgi not yet supported
  #     # uwsgi = ''
  #     # '';

  #   }."${socketType}";

  # in
  # {
  #   virtualHosts."${vhost}" = {
  #     root = "${nextcloudPackage}";
  #     extraConfig = ''
  #       client_max_body_size 1024M;
  #       gzip off;
  #       error_page 403 /core/templates/403.php;
  #       error_page 404 /core/templates/404.php;
  #     '';
  #     # NOTE: Don't rely on the order of the locations!
  #     locations = {
  #       "/robots.txt" = {
  #         extraConfig = "allow all;";
  #       };
  #       "/.well-known/carddav" = {
  #         extraConfig = "return 301 $scheme://$host/remote.php/dav;";
  #       };
  #       "/.well-known/caldav" = {
  #         extraConfig = "return 301 $scheme://$host/remote.php/dav;";
  #       };
  #       # Root
  #       "/" = {
  #         extraConfig = ''
  #           rewrite ^ /index.php$uri;
  #         '';
  #       };
  #       # PHP files
  #       "~ ^/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+|core/templates/40[34])\\.php(?:$|/)" = {
  #         extraConfig = phpConfig;
  #       };
  #       # CSS and JavaScript files
  #       "~* ^/(?!${appsInstalledURL}).*\\.(?:css|js)$" = {
  #         tryFiles = "$uri /index.php$uri$is_args$args";
  #       };
  #       # Other static assets
  #       "~* ^/(?!${appsInstalledURL}).*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$" = {
  #         tryFiles = "$uri /index.php$uri$is_args$args";
  #       };
  #       # Locally installed apps:
  #       #
  #       # No need to specify location for PHP files of installed apps???
  #       #
  #       # CSS and JavaScript files for installed apps
  #       "~* ^/${appsInstalledURL}/(.*\\.(?:css|js))$" = {
  #         root = "${appsDir}";
  #         tryFiles = "/$1 =404";
  #       };
  #       # Other static assets for installed apps
  #       "~* ^/${appsInstalledURL}/(.*\\.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg))$" = {
  #         root = "${appsDir}";
  #         tryFiles = "/$1 =404";
  #       };
  #       # Some hidden files
  #       "~ ^/(?:build|tests|config|lib|3rdparty|templates|data|\\.|autotest|occ|issue|indie|db_|console)" = {
  #         extraConfig = "deny all;";
  #       };
  #     };
  #   };
  # };
}
