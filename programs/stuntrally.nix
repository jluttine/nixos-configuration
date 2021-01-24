{ config, pkgs, lib, ... }:

{
  options.programs.stuntrally.enable = lib.mkEnableOption "Stunt Rally";

  config = lib.mkIf config.programs.supertuxkart.enable {
    networking.firewall.allowedTCPPorts = [ 4243 ];
    networking.firewall.allowedUDPPorts = [ 4243 ];
    environment.systemPackages = with pkgs; [ stuntrally ];
  };
}
