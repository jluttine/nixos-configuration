{ lib, config, pkgs, ... }:
with lib;
{

  options.localConfiguration.extraServices.tuhlaajapojat = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    # pythonPackages = pkgs.python3Packages;
    cfg = config.localConfiguration.extraServices;
    # buildPythonPackage = pythonPackages.buildPythonPackage;
    # buildPythonApplication = pythonPackages.buildPythonApplication;
    # # Use nix-prefetch-url --unpack PATH_TO_RELEASE_TAR_GZ to get hash
    # sportsteam = buildPythonPackage rec {
    #   name = "sportsteam-${version}";
    #   version = "0.1.14";
    #   # src = pkgs.fetchFromGitHub {
    #   #   owner = "jluttine";
    #   #   repo = "django-sportsteam";
    #   #   rev = version;
    #   #   sha256 = "0bv9r8hs7bbw5nh1zm59fifjfsbf635p8f37qz6a4xrkkslknqqz";
    #   # };
    #   src = /home/jluttine/Workspace/django-sportsteam;
    #   # Couldn't get the tests working. "App's aren't loaded yet"
    #   doCheck = false;
    #   propagatedBuildInputs = with pythonPackages; [
    #     django_1_9
    #     icalendar
    #   ];
    # };

    tuhlaajapojat = (import ./tuhlaajapojat-django.nix);

    # tuhlaajapojat = buildPythonPackage rec {
    #   name = "tuhlaajapojat-${version}";
    #   version = "1.0";
    #   # src = pkgs.fetchFromGitHub {
    #   #   owner = "jluttine";
    #   #   repo = "django-sportsteam";
    #   #   rev = version;
    #   #   sha256 = "0bv9r8hs7bbw5nh1zm59fifjfsbf635p8f37qz6a4xrkkslknqqz";
    #   # };
    #   src = /home/jluttine/Workspace/tuhlaajapojat.fi;
    #   doCheck = false;
    #   propagatedBuildInputs = with pythonPackages; [sportsteam];
    #   buildInputs = [ pkgs.makeWrapper ];
    #   installPhase = ''
    #     makeWrapper \
    #       ${sportsteam}/bin/manage.py \
    #       $out/bin/tuhlaajapojat-manage.py \
    #       --set DJANGO_SETTINGS_MODULE tuhlaajapojat.settings
    #   '';
    # };

    # tuhlaajapojatManage = buildPythonApplication rec {
    #   name = "tuhlaajapojat-manage";
    #   buildInputs = [ pkgs.makeWrapper ];
    #   propagatedBuildInputs = [ tuhlaajapojat ];
    #   unpackPhase = ":";
    #   configurePhase = "";
    #   dontBuild = true;
    #   doCheck = false;
    #   installPhase = ''
    #     makeWrapper \
    #       ${sportsteam}/bin/manage.py \
    #       $out/bin/tuhlaajapojat-manage.py \
    #       --set DJANGO_SETTINGS_MODULE tuhlaajapojat.settings
    #   '';
    # };

    # tuhlaajapojatManage = pkgs.runCommand "tuhlaajapojat-manage"
    # {
    #   buildInputs = [ pkgs.makeWrapper ];
    #   propagatedBuildInputs = [ tuhlaajapojat ];
    # }
    # ''
    #   makeWrapper \
    #     ${sportsteam}/bin/manage.py \
    #     $out/bin/tuhlaajapojat-manage.py \
    #     --set DJANGO_SETTINGS_MODULE tuhlaajapojat.settings
    # '';

  in mkIf cfg.tuhlaajapojat {

    # services.nginx.virtualHosts."tuhlaajapojat.fi" = {
    #   serverName = "tuhlaajapojat.fi";
    # };

    # Group and user IDs for tuhlaajapojat
    users.extraGroups.tuhlaajapojat.gid = 301;
    users.extraUsers.tuhlaajapojat = {
      group = "tuhlaajapojat";
      uid = 301;
    };

    services.uwsgi = {
      enable = true;
      # user = "nginx";
      # group = "nginx";
      plugins = [ "python3" ];
      # Emperor instance
      instance = {
        type = "emperor";
        vassals = {
          tuhlaajapojat = {
            type = "normal";
            # uid = "nginx";
            # gid = "nginx";
            #chmod = "660";
            #pythonpath = tuhlaajapojatSettings;
            pythonPackages = self: with self; [
              #sportsteam
              #tuhlaajapojatSettings
              tuhlaajapojat
            ];
            # env = [
            #   #"TUHLAAJAPOJAT_DATABASE_NAME=/var/lib/tuhlaajapojat.fi/tuhlaajapojat.db"
            #   #"TUHLAAJAPOJAT_SECRET_KEY=somethinghere"
            #   #"TUHLAAJAPOJAT_DEBUG=true"
            # ];
            module = "tuhlaajapojat.wsgi";
            socket = "${config.services.uwsgi.runDir}/tuhlaajapojat.sock";
            # Run with at least 1 process but increase up to 4 when needed
            # cheaper = 1;
            # processes = 4;
          };
        };
      };
    };

    # Virtual host settings
    services.nginx.enable = true;
    services.nginx.virtualHosts."tuhlaajapojat.fi" = {
      serverName = "tuhlaajapojat.fi";
      #root = "${pkgs.nextcloud}";
      default = true;
      # FIXME: Enable (and force) SSL
      enableSSL = false;
      forceSSL = false;
      locations = {
        "/media" = {
          alias = "/var/lib/tuhlaajapojat.fi/media";
        };
        "/static" = {
          alias = "/var/lib/tuhlaajapojat.fi/static";
        };
        "/" = {
          extraConfig = ''
          include ${pkgs.nginx}/conf/uwsgi_params;
          uwsgi_pass unix://${config.services.uwsgi.runDir}/tuhlaajapojat.sock;

          '';
        };
      };
    };

    environment.systemPackages = with pkgs; [
      # tuhlaajapojatManage
    ];

  };

}
