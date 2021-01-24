{ lib, config, pkgs, ... }:
{

  options.programs.weechat.enable = lib.mkEnableOption "Weechat";

  config = lib.mkIf config.programs.weechat.enable {

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
                #weechat-matrix
                wee-slack
              ];
              plugins = builtins.attrValues availablePlugins;
              # plugins = builtins.attrValues (availablePlugins // {
              #   python = availablePlugins.python.withPackages (ps: with ps; [
              #     websocket_client
              #   ]);
              # });
            };
          };
        }
      )
    ];

  };

}
