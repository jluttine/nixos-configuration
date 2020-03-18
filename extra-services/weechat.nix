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
    nixpkgs.overlays = [
      (
        self: super: {
          weechat = super.weechat.override {
            configure = {availablePlugins, ...}: {
              scripts = with pkgs.weechatScripts; [
                #weechat-xmpp
                weechat-matrix
                wee-slack
              ];
              plugins = builtins.attrValues (availablePlugins // {
                python = availablePlugins.python.withPackages (ps: with ps; [
                  websocket_client
                ]);
              });
            };
          };
        }
      )
    ];

  };

}
