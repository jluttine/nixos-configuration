{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.rss = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    domain = mkOption {
      type = types.str;
    };
  };

  config = let
    cfg = config.localConfiguration.extraServices.rss;
  in mkIf cfg.enable {

    # services.nginx = {
    #   enable = true;
    #   virtualHosts."${cfg.domain}" = {
    #     root = "/var/lib/selfoss";
    #     locations."/" = {
    #       extraConfig = ''
    #         fastcgi_split_path_info ^(.+\.php)(/.+)$;
    #         fastcgi_pass unix:/var/run/phpfpm/selfoss_pool.sock;
    #         fastcgi_index index.php;
    #       '';
    #     };
    #     # root = "${cfg.root}";

    #     # locations."/" = {
    #     #   index = "index.php";
    #     # };

    #     # locations."~ \.php$" = {
    #     #   extraConfig = ''
    #     #     fastcgi_split_path_info ^(.+\.php)(/.+)$;
    #     #     fastcgi_pass unix:${phpfpmSocketName};
    #     #     fastcgi_index index.php;
    #     #   '';
    #     # };
    #   };
    # };
    # services.selfoss = {
    #   enable = true;
    # };


    # users.extraUsers = [
    #   {
    #     name = "tt_rss";
    #     uid = 422;
    #   }
    # ];
    # users.extraUsers = optionalAttrs (cfg.user == "nginx") (singleton
    #   { name = "nginx";
    #     group = cfg.group;
    #     uid = config.ids.uids.nginx;
    #   });
    # services.nginx.enable = true;
    # services.mysql = {
    #   enable = true;
    #   package = pkgs.mariadb;
    #   ensureDatabases = [ "tt_rss" ];
    #   ensureUsers = [
    #     {
    #       name = "tt_rss";
    #       ensurePermissions = {
    #         "tt_rss.*" = "ALL PRIVILEGES";
    #       };
    #     }
    #   ];
    # };
    services.tt-rss = {
      enable = true;
      virtualHost = cfg.domain;
      selfUrlPath = "http://${cfg.domain}/";
      database = {
        type = "mysql";
      };
    };

  };

}
