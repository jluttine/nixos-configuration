{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.weechat = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.weechat {

    networking.firewall = {
      # WeeChat relay port.
      allowedTCPPorts = [ 9001 ];
    };
    environment.systemPackages = with pkgs; [
      tmux
      weechat
    ];

  };

}
