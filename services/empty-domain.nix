{ lib, config, pkgs, ... }:

{

  options.services.emptyDomain = {
    enable = lib.mkEnableOption "empty dummy domain";
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf config.services.emptyDomain.enable {
    services.nginx = {
      enable = true;
      virtualHosts."${config.services.emptyDomain.domain}" = {
        default = true;
        forceSSL = true;
        enableACME = true;
        # Return 403 for everything
        locations = {
          "/" = {
            return = "403";
          };
        };
      };
    };

  };

}
