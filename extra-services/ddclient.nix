{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.ddclient = mkOption {
    type = types.attrsOf (types.listOf types.str);
    default = { };
  };

  config = let
    cfg = config.localConfiguration.extraServices.ddclient;
    account = import ./ddclient-account.nix;

  in mkIf (cfg != { }) {

    services.ddclient = {
      enable = true;
      server = "api.cloudflare.com/client/v4";
      username = account.username;
      password = account.password;
      protocol = "cloudflare";
      domains = [];
      extraConfig = let
        zones = attrNames cfg;
      in lib.concatStrings (
        map (
          zone: let
            domains = lib.concatStringsSep "," cfg."${zone}";
          in ''
            zone=${zone}
            ${domains}
          ''
        ) zones
      );
    };

    # Fix build inputs of ddclient in order to support Cloudflare. See:
    # https://github.com/NixOS/nixpkgs/issues/26691
    nixpkgs.config.packageOverrides = super: let self = super.pkgs; in {
      ddclient = super.ddclient.overrideAttrs (
        oldAttrs: rec {
          buildInputs = oldAttrs.buildInputs ++ [ pkgs.perlPackages.JSONAny ];
        }
      );
    };

  };

}
