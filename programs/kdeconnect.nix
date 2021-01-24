{ config, pkgs, lib, ... }:

{
  options.programs.kdeconnect.enable = lib.mkEnableOption "KDE Connect";

  config = lib.mkIf config.programs.kdeconnect.enable {
    networking.firewall = {
      allowedTCPPortRanges = [{
        from = 1714;
        to = 1764;
      }];
      allowedUDPPortRanges = [{
        from = 1714;
        to = 1764;
      }];
    };
    environment.systemPackages = with pkgs; [ kdeconnect ];
  };
}
