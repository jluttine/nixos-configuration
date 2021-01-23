{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.emacs = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.emacs {

    services.emacs = {
      enable = true;
      install = true;
    };
  };

}
