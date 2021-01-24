{ config, pkgs, lib, ... }:

{
  options.programs.xonotic.enable = lib.mkEnableOption "Xonotic";

  config = lib.mkIf config.programs.xonotic.enable {
    networking.firewall.allowedTCPPorts = [ 26000 ];
    networking.firewall.allowedUDPPorts = [ 26000 ];
    environment.systemPackages = with pkgs; [ xonotic ];
  };
}
