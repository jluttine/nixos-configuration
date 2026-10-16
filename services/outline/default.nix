{ config, lib, pkgs, ... }:

with lib;

let
  secretFile = "/var/lib/dex/secrets/outline";
  url = "outline.nipsu.fi";
in {
  config = mkIf services.outline.enable {

    # Outline uses BSL license. It's open-source but doesn't allow commercial
    # use. Perhaps we're ok with that for now.
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "outline"
    ];

    # Dex for authentication
    services.dex = {
      enable = true;
      settings = {
        staticClients = [
          {
            id = "outline";
            name = "Outline Client";
            redirectURIs = [ "https://${url}/auth/oidc.callback" ];
            secretFile = secretFile;
          }
        ];
      };
    };

    # Outline service itself
    services.outline = {
      publicUrl = "https://${url}";
      port = 3000;
      forceHttps = false;
      storage.storageType = "local";
      oidcAuthentication = {
        authUrl = "https://dex.nipsu.fi/auth";
        tokenUrl = "https://dex.nipsu.fi/token";
        userinfoUrl = "https://dex.nipsu.fi/userinfo";
        clientId = "outline";
        secretFile = secretFile;
        scopes = [ "openid" "email" "profile" ];
        usernameClaim = "preferred_username";
        displayName = "Dex";
      };
    };

    # Nginx as a reverse proxy
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${url}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.outline.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header X-Scheme $scheme;
          '';
        };
      };
    };

  };
}
