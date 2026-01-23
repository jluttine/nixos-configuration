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
      (
        self: super: {
          jellyfin-media-player = super.jellyfin-media-player.overrideAttrs (
            old: {
              buildInputs = old.buildInputs ++ [ pkgs.makeWrapper ];
              postInstall = let
                envvars = lib.escapeShellArgs (
                  builtins.concatLists (
                    lib.mapAttrsToList (
                      envvar: value: [ "--set" envvar value ]
                    ) (
                      config.nixpkgs.jellyfinMediaPlayerEnv
                    )
                  )
                );
              in (old.postInstall or "") + ''
                wrapProgram "$out/bin/jellyfin-desktop" ${envvars}
              '';
            }
          );
        }
      )
    ];
  };

}
