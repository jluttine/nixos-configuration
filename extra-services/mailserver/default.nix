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
      extraConfig = ''
        # No local delivery
        local_recipient_maps =
        local_transport = error: local main delivery disabled

        # Use Salmon LMTP as a relay
        relay_transport = lmtp:127.0.0.1:8823
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
