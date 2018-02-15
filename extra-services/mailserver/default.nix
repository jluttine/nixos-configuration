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
      version = "0.1.0";
      # src = /home/jluttine/Workspace/mailserver;
      src = pkgs.fetchFromGitHub {
        owner = "jluttine";
        repo = pname;
        rev = version;
        sha256 = "1bz67hfjqpimawjx2jmd114rv8ybhsbwkbbvml2nls684cgm7f0q";
      };
      propagatedBuildInputs = [ ps.requests ps.salmon-mail ];

      # Unit tests expect these directories to be present
      preCheck = ''
        mkdir -p logs
        mkdir -p run
      '';
    };

  in mkIf cfg.enable {
    services.salmon = {
      enable = true;
      bootModule = "mailserver.config.boot";
      settingsModule = "mailserver.config.settings";
      pythonPackages = pkgs.python3Packages;
      extraLibs = (ps: [(mailserver ps)]);
    };
  };

}
