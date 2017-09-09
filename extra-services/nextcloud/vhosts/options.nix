{

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

}
