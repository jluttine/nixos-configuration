{ lib, pkgs }:

with lib;

# TODO: Use this approach to add settings to virtual hosts!
#
# https://github.com/NixOS/nixos/blob/master/modules/services/networking/ssh/sshd.nix#L224

{

  serverConfig = {

    vhost = mkOption {
      type = types.str;
      description = "Virtual host for Nextcloud.";
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
    description = "Path to Nextcloud config, data, apps and asset directories.";
  };

  adminUser = mkOption {
    type = types.str;
    default = "admin";
    description = "User name of the Nextcloud admin account.";
  };

  adminPassword = mkOption {
    type = types.str;
    description = "Password of the Nextcloud admin account.";
  };

  phpPackage = mkOption {
    type = types.package;
    default = pkgs.php;
    defaultText = "pkgs.php";
    description = "PHP package to use.";
  };

  phpUser = mkOption {
    type = types.str;
    default = "nextcloud";
    description = "User account under which Nextcloud runs.";
  };

  phpGroup = mkOption {
    type = types.str;
    default = "nextcloud";
    description = "Group account under which Nextcloud runs.";
  };

  dbType = mkOption {
    type = types.str;
    default = "mysql";
    description = "";
  };

  dbName = mkOption {
    type = types.str;
    default = "nextcloud";
    description = "";
  };

  dbUser = mkOption {
    type = types.str;
    default = "nextcloud";
    description = "";
  };

  dbPassword = mkOption {
    type = types.str;
    default = "password";
    description = "";
  };

}
