{ config, lib, pkgs, ... }:

{
  options = {
    nixpkgs.jellyfinMediaPlayerEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
  };

  config = {
    nixpkgs.overlays = [
    ];
  };

}
