{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.adb = mkOption {
    type = types.bool;
    default = false;
  };

  config.programs = {
    adb.enable = config.localConfiguration.extraServices.adb;
  };

}
