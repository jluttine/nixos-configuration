{ lib, config, ... }:
with lib;
{

  options.localConfiguration.extraServices.sshd = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.sshd {

    services.openssh = {
      enable = true;
      permitRootLogin = "no";
      ports = [6662];
      passwordAuthentication = false;
    };

    programs.mosh = {
      enable = true;
    };

  };

}
