{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.adb = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    enabled = config.localConfiguration.extraServices.adb;
  in {
    programs.adb.enable = enabled;
    nixpkgs.config.android_sdk.accept_license = enabled;
  };

}
