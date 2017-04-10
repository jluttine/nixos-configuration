{ config, pkgs, lib, ... }:

with lib;

{

  # TODO: Support a list of Nextcloud configurations.

  # Define options
  options = {
    services.webapps.nextcloud = (import ./nextcloud-options.nix) { inherit lib; inherit pkgs; };
  };

  # Create system configurations based on Nextcloud configuration
  config = (import ./nextcloud-config.nix) { inherit pkgs; inherit lib; cfg = config.services.webapps.nextcloud; };
 
}

