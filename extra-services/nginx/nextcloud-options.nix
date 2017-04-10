{ lib, pkgs }:

with lib;

{

  enable = mkEnableOption "Enable Nextcloud instance.";

  serverConfig = {

    server = mkOption {
      type = types.str;
      description = "Web server for Nextcloud (Nginx, Apache, etc).";
    };

    vhost = mkOption {
      type = types.str;
      description = "Virtual host for Nextcloud.";
    };

    user = mkOption {
      type = types.str;
      description = "User account under which the web server runs.";
    };

    group = mkOption {
      type = types.str;
      description = "Group account under which the web server runs.";
    };

  };

  package = mkOption {
    type = types.package;
    default = pkgs.nextcloud;
    defaultText = "pkgs.nextcloud";
    description = "Nextcloud package to use.";
  };

  path = mkOption {
    type = types.path;
    default = "/var/lib/nextcloud";
    description = "The path of Nextcloud config, data, apps and assets.";
  };

  user = mkOption {
    type = types.str;
    default = "nextcloud";
    description = "User account under which Nextcloud runs.";
  };

  group = mkOption {
    type = types.str;
    default = "nextcloud";
    description = "Group account under which Nextcloud runs.";
  };

}
