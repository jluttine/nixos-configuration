{ lib, config, pkgs, ... }:
{

  config = let
    dataDir = config.services.mopidy.dataDir;
  in lib.mkIf config.services.mopidy.enable {

    services.mopidy = {
      configuration = ''
      [mpd]
      hostname = 0.0.0.0
      [audio]
      output = pulsesink server=127.0.0.1
      '';
      # [audio]
      # output = audioresample ! audioconvert ! vorbisenc ! oggmux ! shout2send mount=mopidy ip=127.0.0.1 port=8000 password=password
      extensionPackages = [
        pkgs.mopidy-iris
        # pkgs.mopidy-local-sqlite
      ];
    };

    # Allow Mopidy to play sound via Pulseaudio that might be running under some
    # other user. See:
    # https://wiki.archlinux.org/index.php/Music_Player_Daemon/Tips_and_tricks#Local_.28with_separate_mpd_user.29
    hardware.pulseaudio.extraConfig = ''
      load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1
    '';

    # Change this as the default doesn't set permissions correctly
    systemd.services.mopidy.preStart = "mkdir -p ${dataDir} && chown -R mopidy:mopidy  ${dataDir} && chmod -R o-rwx ${dataDir}";

    # Mopidy HTTP server runs on port 6680 for localhost only. If you want to
    # access that outside, create a reverse proxy with nginx, and probably add
    # authentication too.
    networking.firewall.allowedTCPPorts = [
      #6600 # MPD server
      #6680 # MPD server
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
