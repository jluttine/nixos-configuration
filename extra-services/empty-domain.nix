
{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.emptyDomain = mkOption {
    type = types.nullOr types.str;
    default = null;
  };

  config = let
    domain = config.localConfiguration.extraServices.emptyDomain;
  in mkIf (domain != null) {
    services.nginx = {
      virtualHosts."${domain}" = {
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
