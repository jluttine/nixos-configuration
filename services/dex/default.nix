{ config, lib, pkgs, ... }:

with lib;
{
  config = mkIf config.services.dex.enable {

    services.dex.settings = {
      issuer = mkDefault "https://dex.nipsu.fi";
      storage.type = "sqlite3";
      web.http = "127.0.0.1:5556";
      enablePasswordDB = true;
      staticPasswords = import ./passwords.nix;
    };

    # Nginx as reverse proxy
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."${url}" = {
        onlySSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${config.services.dex.settings.web.http}";
          proxyWebsockets = true;
        };
      };
    };

  };
}
