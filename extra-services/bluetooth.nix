{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.bluetooth = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = let
    cfg = config.localConfiguration.extraServices.bluetooth;
  in mkIf cfg.enable {

    hardware = {

      bluetooth.enable = true;

      # NixOS allows either a lightweight build (default) or full build of
      # PulseAudio to be installed. Only the full build has Bluetooth support,
      # so it must be selected here.
      pulseaudio.package = pkgs.pulseaudioFull;

    };

  };

}
