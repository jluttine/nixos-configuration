{
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
}
