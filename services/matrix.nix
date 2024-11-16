{ lib, config, pkgs, ... }:

# See: https://nixos.org/manual/nixos/stable/#module-services-matrix

let
  baseUrl = "https://matrix.nipsu.fi";
  clientConfig."m.homeserver".base_url = baseUrl;
  serverConfig."m.server" = "matrix.nipsu.fi:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in {

  config = lib.mkIf config.services.matrix-synapse.enable {
    networking.firewall.allowedTCPPorts = [ 8448 ];
    services = {
      matrix-synapse = {
        settings = {
          server_name = "matrix.nipsu.fi";
          enable_registration = false;
          registration_shared_secret_path = "/var/lib/matrix-synapse/registration_shared_secret";
          public_baseurl = baseUrl;
          listeners = [
            { port = 8008;
              bind_addresses = [ "::1" ];
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [ {
                names = [ "client" "federation" ];
                compress = true;
              } ];
            }
          ];
        };
      };
      postgresql = {
        enable = lib.mkDefault true;
        # NOTE: This doesn't work because it creates the database with wrong collation.
        ensureDatabases = [ "matrix-synapse" ];
        # Use this manual command instead:
        #
        # sudo -u postgres createdb --encoding=UTF8 --locale=C --template=template0 --owner=matrix-synapse matrix-synapse
        #
        # For more details, see: https://element-hq.github.io/synapse/latest/postgres.html#set-up-database
        ensureUsers = [
          {
            name = "matrix-synapse";
            ensureDBOwnership = true;
          }
        ];
      };
      # Reverse proxy so we can have domain name and SSL
      nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts."matrix.nipsu.fi" = {
          forceSSL = true;
          enableACME = true;
          # This section is not needed if the server_name of matrix-synapse is equal to
          # the domain (i.e. example.org from @foo:example.org) and the federation port
          # is 8448.
          # Further reference can be found in the docs about delegation under
          # https://element-hq.github.io/synapse/latest/delegate.html
          locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
          # This is usually needed for homeserver discovery (from e.g. other Matrix clients).
          # Further reference can be found in the upstream docs at
          # https://spec.matrix.org/latest/client-server-api/#getwell-knownmatrixclient
          locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
          # It's also possible to do a redirect here or something else, this vhost is not
          # needed for Matrix. It's recommended though to *not put* element
          # here, see also the section about Element.
          locations."/".extraConfig = ''
            return 404;
          '';
          # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
          # *must not* be used here.
          locations."/_matrix".proxyPass = "http://[::1]:8008";
          # Forward requests for e.g. SSO and password-resets.
          locations."/_synapse/client".proxyPass = "http://[::1]:8008";
          ## See: https://element-hq.github.io/synapse/latest/reverse_proxy.html#nginx
          #listen = [
          #  {
          #    addr = "0.0.0.0";
          #    port = 443;
          #    ssl = true;
          #  }
          #  {
          #    addr = "0.0.0.0";
          #    port = 8448;
          #    ssl = true;
          #    extraParameters = [ "default_server" ];
          #  }
          #];
          #locations = {
          #  "~ ^(/_matrix|/_synapse/client)" = {
          #    # note: do not add a path (even a single /) after the port in `proxy_pass`,
          #    # otherwise nginx will canonicalise the URI and cause signature verification
          #    # errors.
          #    proxyPass = "http://localhost:8008";
          #    recommendedProxySettings = true;
          #    extraConfig = ''
          #      proxy_set_header X-Forwarded-For $remote_addr;
          #      proxy_set_header X-Forwarded-Proto $scheme;
          #      proxy_set_header Host $host;
          #      client_max_body_size 50M;
          #    '';
          #  };
          #};
          ## Synapse responses may be chunked, which is an HTTP/1.1 feature.
          #extraConfig = ''
          #  proxy_http_version 1.1;
          #'';
        };
      };
    };

  };

}
