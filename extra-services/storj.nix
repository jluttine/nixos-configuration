{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.storj = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.storj {

  };

}
