{ lib, pkgs, config, ... }:

with lib;

{

  options = {
    services.webapps.nextcloud = mkOption {
      type = types.attrsOf (import ./options.nix);
      default = {};
      description = "Nextcloud instances";
    };
    foobar = mkOption {

    };
  };

  config.foobar = (
    # FIXME: HOW TO MERGE?
    # Create global config from each nextcloud instance configuration
    mapAttrs' (import ./config.nix) config.services.webapps.nextcloud
  );

}

#config = mapAttrs' someFunction config.some.attributes
