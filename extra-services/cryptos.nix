{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.cryptos = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = let
    cfg = config.localConfiguration.extraServices.cryptos;
  in mkIf cfg.enable {

    environment.systemPackages = with pkgs; [

      # Wallets
      electrum
      monero
      electron-cash

      # Tools
      zbar

    ];
  };

}
