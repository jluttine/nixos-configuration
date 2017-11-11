{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.bluray = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.bluray {

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
      aacskeys
    ];

  };

}
