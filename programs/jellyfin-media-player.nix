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
              patches = (old.patches or []) ++ [
                # See: https://github.com/jellyfin/jellyfin-media-player/pull/279
                ./dvbsub.patch
              ];
              buildInputs = old.buildInputs ++ [ pkgs.makeWrapper ];
              postInstall = let
                envvars = lib.escapeShellArgs (
                  builtins.concatLists (
                    lib.mapAttrsToList (
                      envvar: value: [ "--set" envvar value ]
                    ) (
                      # See:
                      # https://github.com/jellyfin/jellyfin-media-player/issues/231#issuecomment-1293408450
                      { QT_XCB_GL_INTEGRATION = "xcb_egl"; } //
                      config.nixpkgs.jellyfinMediaPlayerEnv
                    )
                  )
                );
              in (old.postInstall or "") + ''
                wrapProgram "$out/bin/jellyfinmediaplayer" ${envvars}
              '';
            }
          );
        }
      )
    ];
  };

}
