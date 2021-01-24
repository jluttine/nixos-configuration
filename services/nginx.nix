{ lib, config, ... }:

{
  config = lib.mkIf config.services.nginx.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    services.nginx = {
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
  };
}
