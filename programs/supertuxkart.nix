{ config, pkgs, lib, ... }:

{
  options.programs.supertuxkart.enable = lib.mkEnableOption "SuperTuxKart";

  config = lib.mkIf config.programs.supertuxkart.enable {
    networking.firewall.allowedTCPPorts = [ 2757 2759 ];
    networking.firewall.allowedUDPPorts = [ 2757 2759 ];
    environment.systemPackages = with pkgs; [ supertuxkart ];
  };
}
