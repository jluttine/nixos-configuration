{ config, lib, pkgs, ... }:

{
  imports = [
    ./syncthing-ids.nix
  ];
  options = {
    services.syncthing.defaultVersioning = lib.mkOption {
      type = with lib.types; attrsOf (either str (attrsOf str));
      default = {
        type = "trashcan";
        params.cleanoutDays = "1";
      };
    };
  };
  config = {
    services.syncthing = {
      openDefaultPorts = lib.mkDefault true;
      settings = {
        gui = let
          secrets = import ./syncthing-secrets.nix;
        in {
          # NOTE: Don't disable GUI! I suppose NixOS is communicating with the
          # API and stops working if GUI is disabled..
          tls = true;
          user = secrets.user;
          password = secrets.password;
        };
        # NOTE: Device and folder IDs are defined in syncthing-ids.nix
        folders = let
          isHost = n: (lib.toLower n) == (lib.toLower config.networking.hostName);
          # Add default configs. Note that folderConfig can override the defaults
          # because folderConfig is on the LHS of //
          addDefaults = lib.mapAttrs (folderName: folderConfig:
            {
              path = "${config.services.syncthing.dataDir}/${folderName}";
              enable = builtins.any isHost folderConfig.devices;
              versioning = lib.mkDefault config.services.syncthing.defaultVersioning;
            } // folderConfig
          );
          # All folders.
          #
          # TODO: Encrypt all folders on nipsu?
          allFolders = {
            Jaakko = {
              devices = [
                "Leevi"
                "Nipsu"
              ];
            };
            Meri = {
              devices = [
                "Martta"
                "Nipsu"
              ];
            };
            Yhteinen = {
              devices = [
                "Leevi"
                "Martta"
                "Nipsu"
              ];
            };
            Liikkuva = {
              devices = [
                "Leevi"
                "Martta"
                "Nipsu"
                "Taskuloinen"
                "MerinOnePlus"
                "MerinPixel"
              ];
            };
            Kamera-Jaakko = {
              devices = [
                "Leevi"
                "Nipsu"
                "Taskuloinen"
              ];
            };
            Kamera-Meri = {
              devices = [
                "Martta"
                "MerinOnePlus"
                "MerinPixel"
                "Nipsu"
              ];
            };
            Kalenteri-Jaakko = {
              devices = [
                "Leevi"
                "Nipsu"
                "Taskuloinen"
              ];
            };
            Kalenteri-Yhteinen = {
              devices = [
                "Leevi"
                "Nipsu"
                "Taskuloinen"
                "MerinOnePlus"
              ];
            };
            Kontaktit-Jaakko = {
              devices = [
                "Nipsu"
                "Taskuloinen"
              ];
            };
            Orgzly-Jaakko = {
              devices = [
                "Leevi"
                "Nipsu"
                "Taskuloinen"
              ];
            };
            Orgzly-Meri = {
              devices = [
                "Martta"
                "MerinOnePlus"
                "MerinPixel"
                "Nipsu"
              ];
            };
            Orgzly-Yhteinen = {
              devices = [
                "Leevi"
                "Martta"
                "MerinOnePlus"
                "MerinPixel"
                "Nipsu"
                "Taskuloinen"
              ];
            };
            Puhelut-Jaakko = {
              devices = [
                "Leevi"
                "Nipsu"
                "Taskuloinen"
              ];
            };
            Instagram-Meri = {
              devices = [
                "Leevi"
                "Martta"
                "MerinOnePlus"
                "MerinPixel"
                "Nipsu"
                "Taskuloinen"
              ];
            };
            Lompakot = {
              devices = [
                "Leevi"
                "Martta"
                "Nipsu"
                "Taskuloinen"
              ];
              # TODO: Encrypt on mobiles and nipsu
              #
              # Never delete
              versioning = lib.mkDefault {
                type = "simple";
                params.cleanoutDays = "0";
                params.keep = "9999999";
              };
            };
          };
        in addDefaults allFolders;
      };
    };
  };
}
