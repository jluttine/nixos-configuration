{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.syncthing = mkOption {
    type = types.attrs;
    default = {};
  };

  config.services.syncthing =
    config.localConfiguration.extraServices.syncthing;

}
