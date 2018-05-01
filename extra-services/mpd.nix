{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.mpd = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = let
    cfg = config.localConfiguration.extraServices.mpd;
    dataDir = config.services.mopidy.dataDir;
  in mkIf cfg.enable {

    services.mopidy = {
      enable = true;
      configuration = ''
      [mpd]
      hostname = 0.0.0.0
      [local]
      enabled = true
      library = sqlite
      media_dir = ${dataDir}/library
      scan_timeout = 1000
      scan_flush_threshold = 100
      scan_follow_symlinks = false
      excluded_file_extensions =
        .directory
        .html
        .jpeg
        .jpg
        .log
        .nfo
        .png
        .txt
      '';
      # [audio]
      # output = audioresample ! audioconvert ! vorbisenc ! oggmux ! shout2send mount=mopidy ip=127.0.0.1 port=8000 password=password
      extensionPackages = [
        pkgs.mopidy-local-sqlite
      ];
    };

    # Change this as the default doesn't set permissions correctly
    systemd.services.mopidy.preStart = "mkdir -p ${dataDir} && chown -R mopidy:mopidy  ${dataDir} && chmod -R o-rwx ${dataDir}";

    # Mopidy HTTP server runs on port 6680 for localhost only. If you want to
    # access that outside, create a reverse proxy with nginx, and probably add
    # authentication too.
    networking.firewall.allowedTCPPorts = [
      6600 # MPD server
      # 8000 # Icecast server
     ];

    # # See: https://docs.mopidy.com/en/latest/audio/#streaming-through-icecast
    # services.icecast = {
    #   enable = true;
    #   hostname = "192.168.1.10";
    #   listen.address = "::";
    #   admin.password = "password";
    # };

    # Reverse proxy so we can have domain name and SSL
    # services.nginx = {
    #   enable = true;
    #   virtualHosts."${cfg.domain}" = {
    #     forceSSL = cfg.ssl;
    #     enableACME = cfg.ssl;
    #     locations = {
    #       "/" = {
    #         proxyPass = "http://localhost:5232/"; # The / is important!
    #         extraConfig = ''
    #           proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    #           proxy_pass_header Authorization;
    #         '';
    #       };
    #     };
    #   };
    # };

  };

}
