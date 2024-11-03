{ lib, config, pkgs, ... }:

{

  options.programs.cryptos.enable = lib.mkEnableOption "various crypto wallets";

  config = lib.mkIf config.programs.cryptos.enable {

    environment.systemPackages = with pkgs; [

      # Wallets
      electrum
      monero-cli
      monero-gui
      #electron-cash
      #nano-wallet

      # Tools
      zbar

    ];
  };

}
