{ lib, config, pkgs, ... }:
let
  pythonPackages = pkgs.python3Packages.override {
    overrides = self: super: {
       django = super.django_4;
    };
  };
  buildPythonPackage = pythonPackages.buildPythonPackage;

  django-ordered-model = with pythonPackages; buildPythonPackage rec {
    pname = "django-ordered-model";
    version = "3.7.4";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-8li5diUlwApTAJ6C+Li/KjqjFei0U+KB6P27/iuMs7o=";
    };

    nativeBuildInputs = [
      setuptools
    ];

    checkInputs = [
      djangorestframework
    ];

    propagatedBuildInputs = [
      django
    ];

    checkPhase = ''
      runHook preCheck
      ${python.interpreter} -m django test --settings tests.settings
      runHook postCheck
    '';

    pythonImportsCheck = [ "ordered_model" ];
  };

  bayesleague = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "bayes-league";
    version = "0.15.3";
    src = pkgs.fetchFromGitHub {
      owner = "jluttine";
      repo = pname;
      rev = version;
      sha256 = "sha256-wog5L3G5whgZdXZT1Y77IYJGiQdoyTHkPif2mTLPXyM=";
    };
    format = "pyproject";
    # Couldn't get the tests working. "App's aren't loaded yet"
    doCheck = false;
    buildInputs = with pythonPackages; [
      setuptools
    ];
    propagatedBuildInputs = with pythonPackages; [
      django
      numpy
      scipy
      autograd
      django-ordered-model
    ];
  };

  directory = "/var/lib/uwsgi/bayesleague";

  settings = pkgs.substituteAll {
    name = "bayesleague-settings";
    src = ./settings.json;
    inherit directory;
  };

  manageBayesLeague = pkgs.writeScriptBin
    "manage-bayesleague"
    ''
      #!${pkgs.stdenv.shell}
      BAYESLEAGUE_SETTINGS_JSON=${settings} ${bayesleague}/bin/manage.py "$@"
    '';

  socketUser = "nginx";
  socket = "${config.services.uwsgi.runDir}/bayesleague.sock";

  robotsTxt = pkgs.writeTextDir "robots.txt" ''
    User-agent: *
    Disallow: /
  '';

in {

  options.services.bayesleague.enable = lib.mkEnableOption "Bayes League website";

  config = lib.mkIf config.services.bayesleague.enable {

    services.uwsgi = {
      enable = true;
      # nginx needs to have access to the socket and the static files. It's
      # easiest just to use nginx uid/gid for uwsgi too. It'd be probably better
      # though, if we used separate uwsgi user for uwsgi and then just set
      # permissions so that everything works correctly..
      user = "nginx";
      group = "nginx";
      #user = "uwsgi";
      #group = "uwsgi";
      plugins = [ "python3" ];
      # Emperor instance
      instance = {
        type = "emperor";
        vassals = {
          bayesleague = {
            type = "normal";
            # Unfortunately, the socket file is created with user:group of the
            # main uwsgi process. Thus, these don't make a difference?
            #
            #uid = "nginx";
            #gid = "nginx";
            "chmod-socket" = "600";
            socket = socket;
            pythonPackages = self: with self; [ bayesleague ];
            module = "website.wsgi:application";
            env = [
              "BAYESLEAGUE_SETTINGS_JSON=${settings}"
            ];
            # Run with at least 2 process but increase up to 16 when needed
            # https://uwsgi-docs.readthedocs.io/en/latest/Cheaper.html#spare2-cheaper-algorithm
            #
            # cheaper-algo = "spare2";  # spare2 isn't yet available uwsgi 2.0. it'd be great
            #
            # It could be installed as a backport though:
            # https://github.com/KLab/uwsgi-cheaper-spare2?tab=readme-ov-file
            cheaper-algo = "spare";
            cheaper = 4;
            processes = 16;
            cheaper-step = 4;
            cheaper-idle = 60;  # affects spare2 only?
          };
        };
      };
    };

    # Before starting the uWSGI service:
    # - create state directory (if doesn't exist)
    # - run migrations
    # - collect static
    systemd.services.uwsgi.serviceConfig = {
      # Create directory for data
      StateDirectory = "uwsgi";
      # Create directory for the socket
      RuntimeDirectory = "uwsgi";
    };
    systemd.services.uwsgi.preStart = ''
      ${manageBayesLeague}/bin/manage-bayesleague migrate
      ${manageBayesLeague}/bin/manage-bayesleague collectstatic --no-input
    '';

    services.nginx = {
      enable = true;
      virtualHosts."liiga.nipsu.fi" = {
        forceSSL = true;
        enableACME = true;

        locations = {
          "/robots.txt" = {
            root = "${robotsTxt}";
          };
          "/media/" = {
            alias = "${directory}/media/";
          };
          "/static/" = {
            alias = "${directory}/static/";
          };
          "/" = {
            extraConfig = ''
              uwsgi_pass unix://${socket};
              include ${pkgs.nginx}/conf/uwsgi_params;
              uwsgi_read_timeout 600;
            '';
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      manageBayesLeague
    ];

  };

}
