{ lib, config, pkgs, ... }:
with lib;
{

  imports = [
    ./salmon.nix
  ];

  options.localConfiguration.extraServices.mailserver = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = let

    cfg = config.localConfiguration.extraServices.mailserver;

    mailserver = ps: ps.buildPythonPackage rec {
      pname = "mailserver";
      version = "0.1.2";
      src = pkgs.fetchFromGitHub {
        owner = "jluttine";
        repo = pname;
        rev = version;
        sha256 = "0wpmkml6vbynljz02alqrywx2qx11906p43ig541jvwvgmx44l9x";
      };
      propagatedBuildInputs = [ ps.requests ps.salmon-mail ];

      # Unit tests expect these directories to be present
      preCheck = ''
        mkdir -p logs
        mkdir -p run
      '';
    };

  in mkIf cfg.enable {

    # Open port for SMTP
    networking.firewall.allowedTCPPorts = [ 25 ];

    # Use Postfix as a SMTP mail gateway which forwards emails to Salmon LMTP
    # server.
    services.postfix = {
      enable = true;
      hostname = "mail.tuhlaajapojat.fi";
      # Only accept mail from the host. Perhaps disable sending?
      networksStyle = "host";
      # No local delivery
      destination = [ ];
      # Relay @tuhlaajapojat.fi to Salmon LMTP server
      relayDomains = [ "tuhlaajapojat.fi" ];
      transport = ''
        tuhlaajapojat.fi lmtp:localhost:8823
      '';
      mapFiles = {
        relay_recipients = pkgs.writeText "postfix-relay_recipients" ''
          @tuhlaajapojat.fi x
        '';
      };
      extraConfig = ''
        local_recipient_maps =
        local_transport = error: local main delivery disabled

        relay_recipient_maps = hash:/etc/postfix/relay_recipients
      '';
    };

    # Salmon runs LMTP server under port 8823
    services.salmon = {
      enable = true;
      bootModule = "mailserver.config.boot";
      settingsModule = "mailserver.config.settings";
      pythonPackages = pkgs.python3Packages;
      extraLibs = (ps: [(mailserver ps)]);
    };

  };

}
