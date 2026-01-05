{ lib, config, pkgs, ... }:

{

  options.programs.cryptos.enable = lib.mkEnableOption "various crypto wallets";

  config = lib.mkIf config.programs.cryptos.enable {

    environment.systemPackages = with pkgs; [

      # Wallets
      # python.ecdsa dropped, electrum broken
      # See: https://github.com/NixOS/nixpkgs/pull/456881
      #electrum
      monero-cli
      monero-gui
      #electron-cash
      #nano-wallet

      # Tools
      zbar

    ];
  };

}
