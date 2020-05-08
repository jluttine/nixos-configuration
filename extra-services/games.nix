{ config, pkgs, lib, ... }:

with lib;

{
  options.localConfiguration.extraServices.multiplayerGames = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };
  config = mkIf config.localConfiguration.extraServices.multiplayerGames.enable {
    # Port for hosting multiplayer games
    networking.firewall.allowedTCPPorts = [
      26000 # xonotic
      2757 2759 # supertuxkart
      4243 # stuntrally
    ];
    networking.firewall.allowedUDPPorts = [
      26000 # xonotic
      2757 2759 # supertuxkart
      4243 # stuntrally
    ];
    #networking.firewall.allowedUDPPorts = [ 26000 ];
    # The game itself
    environment.systemPackages = with pkgs; [
      xonotic
      stuntrally
      superTuxKart
      # megaglest
      # zeroad
      # hedgewars
      # freeciv
      # openttd
      # teeworlds
    ];
  };
}
