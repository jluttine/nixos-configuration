{ lib, pkgs, config, ... }:

with lib;

{

  imports = [
    ./vhosts/nginx-config.nix
    ./sockets/fpm-config.nix
  ];

  options.services.webapps.nextcloud = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          name = mkOption {
            type = types.str;
          };
          socket.fpm = mkOption {
            # type = types.enum [
            #   (
            #     types.submodule
            #     {
            #       fpm = types.submodule (import ./fpm-options.nix) {inherit lib;};
            #     }
            #   )
            #   # (
            #   #   types.submodule
            #   #   {
            #   #     uwsgi = types.submodule (import ./uwsgi-options.nix) {inherit lib;};
            #   #   }
            #   # )
            # ];

            # See: https://gist.github.com/Infinisil/9c400fd3d831781a2499fbfec74b628b
            type = types.submodule (
              import ./sockets/fpm-options.nix
            );
            # type = types.submodule (
            #   {name, ...}: {
            #     options.path = mkOption {
            #       type = types.str;
            #     };
            #     config.path = mkDefault "John Doe";
            #   }
            # );

              #(import ./sockets/fpm-options.nix) {inherit lib;}

            # type = types.either (
            #   (
            #     types.submodule
            #     {
            #       fpm = types.submodule (import ./fpm-options.nix) {inherit lib;};
            #     }
            #   )
            #   (
            #     types.submodule
            #     {
            #       fpm = types.submodule (import ./fpm-options.nix) {inherit lib;};
            #     }
            #   )
            # );
              # (
              #   types.submodule
              #   {
              #     uwsgi = types.submodule (import ./uwsgi-options.nix) {inherit lib;};
              #   }
              # )
          };
          server = {
            type = types.enum [
              (
                types.submodule
                {
                  nginx = types.submodule (import ./nginx-options.nix) {inherit lib;};
                }
              )
              # (
              #   types.submodule
              #   {
              #     httpd = types.submodule (import ./httpd-options.nix) {inherit lib;};
              #   }
              # )
            ];
          };
        };
      }
    );
    default = {};
  };

}
