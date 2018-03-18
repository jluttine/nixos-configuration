{ lib, config, pkgs, ... }:
with lib;
let
  pythonPackages = pkgs.python3Packages;
  buildPythonPackage = pythonPackages.buildPythonPackage;
  buildPythonApplication = pythonPackages.buildPythonApplication;

  sportsteam = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "django-sportsteam";
    version = "0.1.20";
    src = pkgs.fetchFromGitHub {
      owner = "jluttine";
      repo = pname;
      rev = version;
      sha256 = "1b9y9sadqzcpcl5dc6455vpysv0q4nwph22d1fpb0viyaq1fb1y4";
    };
    # Couldn't get the tests working. "App's aren't loaded yet"
    doCheck = false;
    propagatedBuildInputs = with pythonPackages; [
      django
      icalendar
    ];
  };

  directory = "/var/lib/tuhlaajapojat";

  settingsFile = pkgs.writeText "settings.py" ''
    from sportsteam.settings.prod import *

    DEBUG = False

    TEAM_NAME = 'FC Tuhlaajapojat'
    TEAM_SLUG = 'tuhlaajapojat'
    TEAM_TAG = 'Tuhlaajapojat'

    ADMINS = (
        ('Jaakko Luttinen', 'jaakko.luttinen@iki.fi'),
    )
    MANAGERS = ADMINS

    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME':   '${directory}/tuhlaajapojat.db'
        }
    }

    STATIC_ROOT = '${directory}/static/'
    MEDIA_ROOT = '${directory}/media/'

    # Local time zone for this installation. Choices can be found here:
    # http://en.wikipedia.org/wiki/List_of_tz_zones_by_name
    # although not all choices may be available on all operating systems.
    # If running in a Windows environment this must be set to the same as your
    # system time zone.
    TIME_ZONE = 'Europe/Helsinki'

    # Language code for this installation. All choices can be found here:
    # http://www.i18nguy.com/unicode/language-identifiers.html
    LANGUAGE_CODE = 'fi'

    SITE_ID = 1

    # Make this unique, and don't share it with anybody.
    # Use environment variable here..
    SECRET_KEY = 'foobar'

    ALLOWED_HOSTS = ['*']
  '';

  manageFile = pkgs.writeText "manage.py" ''
    #!/usr/bin/env python
    import os, sys
    if __name__ == "__main__":
        from django.core.management import execute_from_command_line
        execute_from_command_line(sys.argv)
  '';

  setupFile = pkgs.writeText "setup.py" ''
    from setuptools import setup
    setup(
        install_requires = ["sportsteam"],
        scripts          = ["manage.py"],
        packages         = ["tuhlaajapojat"],
        name             = "tuhlaajapojat",
    )
  '';

  tuhlaajapojatSrc = pkgs.runCommand "tuhlaajapojat-source" {} ''
    mkdir -p $out/tuhlaajapojat
    touch $out/tuhlaajapojat/__init__.py
    cp ${setupFile} $out/setup.py
    cp ${settingsFile} $out/tuhlaajapojat/settings.py
    cp ${manageFile} $out/manage.py
  '';

  tuhlaajapojat = buildPythonPackage rec {
    name = "tuhlaajapojat";
    src = tuhlaajapojatSrc;
    propagatedBuildInputs = with pythonPackages; [
      sportsteam
      (pkgs.uwsgi.override { plugins = [ "python3" ]; })
    ];
  };

  settings = "tuhlaajapojat.settings";

  manageTuhlaajapojat = pkgs.writeScriptBin
    "manage-tuhlaajapojat"
    ''
      #!${pkgs.stdenv.shell}
      ${pkgs.sudo}/bin/sudo -u ${socketUser} \
        DJANGO_SETTINGS_MODULE=${settings}   \
        ${tuhlaajapojat}/bin/manage.py       \
        "$@"
    '';

  socketUser = "nginx";
  socket = "${config.services.uwsgi.runDir}/tuhlaajapojat.sock";

  robotsTxt = pkgs.writeText "robots.txt" ''
    User-agent: *
    Disallow: /
  '';

in {

  options.localConfiguration.extraServices.tuhlaajapojat = mkOption {
    type = types.bool;
    default = false;
  };

  config = let
    cfg = config.localConfiguration.extraServices;
  in mkIf cfg.tuhlaajapojat {

    services.uwsgi = {
      enable = true;
      user = "nginx";
      group = "nginx";
      #user = "uwsgi";
      #group = "uwsgi";
      plugins = [ "python3" ];
      # Emperor instance
      instance = {
        type = "emperor";
        vassals = {
          tuhlaajapojat = {
            type = "normal";
            # Unfortunately, the socket file is created with user:group of the
            # main uwsgi process. Thus, these don't make a difference?
            #
            # uid = "nginx";
            # gid = "nginx";
            socket = socket;
            pythonPackages = self: with self; [ tuhlaajapojat ];
            module = "sportsteam.wsgi:application";
            env = [
              "DJANGO_SETTINGS_MODULE=${settings}"
            ];
            # Run with at least 1 process but increase up to 4 when needed
            cheaper = 1;
            processes = 4;
          };
        };
      };
    };

    # Before starting the uWSGI service:
    # - create state directory (if doesn't exist)
    # - run migrations
    # - collect static
    systemd.services.uwsgi.preStart = ''
      mkdir -p ${directory}
      chmod 700 ${directory}
      chown ${socketUser} ${directory}
      ${manageTuhlaajapojat}/bin/manage-tuhlaajapojat migrate
      ${manageTuhlaajapojat}/bin/manage-tuhlaajapojat collectstatic --no-input
    '';

    services.nginx = {
      enable = true;
      virtualHosts."tuhlaajapojat.fi" = {
        serverAliases = ["tuhlaajapojat.fi" "www.tuhlaajapojat.fi"];
        forceSSL = true;
        enableACME = true;

        locations = {
          "/robots.txt" = {
            alias = "${robotsTxt}";
          };
          "/media" = {
            alias = "${directory}/media";
          };
          "/static" = {
            alias = "${directory}/static";
          };
          "/" = {
            extraConfig = ''
              uwsgi_pass unix://${socket};
              include ${pkgs.nginx}/conf/uwsgi_params;
            '';
          };
        };
      };
    };



    environment.systemPackages = with pkgs; [
      manageTuhlaajapojat
    ];

  };

}
