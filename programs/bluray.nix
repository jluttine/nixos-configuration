{ lib, config, pkgs, ... }:

{

  options.programs.bluray.enable = lib.mkEnableOption "blu-ray support";

  config = lib.mkIf config.programs.bluray.enable {

    # Enable libaacs and libbdplus
    nixpkgs.overlays = [
      (
        self: super: {
          libbluray = super.libbluray.override {
            withAACS = true;
            withBDplus = true;
          };
        }
      )
    ];

    environment.systemPackages = with pkgs; [
      vlc
    ];

  };

}
