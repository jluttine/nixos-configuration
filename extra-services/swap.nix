{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.swap = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    device = mkOption {
      type = types.str;
    };
    size = mkOption {
      type = types.int;
    };
  };

  config = let

    cfg = config.localConfiguration.extraServices.swap;

  in mkIf cfg.enable {

    swapDevices = [
      {
        device = cfg.device;
        size = cfg.size;
      }
    ];

  };

}
