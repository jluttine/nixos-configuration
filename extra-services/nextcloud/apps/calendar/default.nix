{lib, pkgs, ...}:

with (import /home/jluttine/Workspace/yarn2nix { inherit pkgs; });
let
  yarnComponents = mkYarnPackage rec {
    name = "yarn-components";
    src = /home/jluttine/Workspace/calendar/js;
    packageJson = /home/jluttine/Workspace/calendar/js/package.json;
    yarnLock = /home/jluttine/Workspace/calendar/js/yarn.lock;
    # NOTE: this is optional and generated dynamically if omitted
    # yarnNix = ./js/yarn.nix;
  };
in pkgs.stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "nextcloud-calendar";
  version = "1.5.6";
  src = /home/jluttine/Workspace/calendar;

  buildInputs = with pkgs; [ which yarn nodejs nodePackages.gulp ];

  bowerComponents = pkgs.buildBowerComponents {
    name = "bower-components";
    # This file is generated with bower2nix in calendar repo js directory.
    generated = ./bower.nix;
    src = /home/jluttine/Workspace/calendar/js;
  };

  patches = [];

  buildPhase = ''
    cp --reflink=auto --no-preserve=mode -R ${yarnComponents}/node_modules ./js/
    cp --reflink=auto --no-preserve=mode -R ${bowerComponents}/bower_components ./js/vendor
    export HOME=$(pwd)
    make build
    make appstore
  '';

  installPhase = ''
    mkdir -p $out/calendar
    cp -R build/appstore/calendar/* $out/calendar/
  '';
}
