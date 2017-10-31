{lib, pkgs, ...}:

with (import /home/jluttine/Workspace/yarn2nix { inherit pkgs; });
let

  version = "1.5.6";
  pname = "calendar";

  source = pkgs.srcOnly {
    stdenv = pkgs.stdenv;
    name = pname;
    src = pkgs.fetchzip {
      url = "https://github.com/nextcloud/${pname}/archive/v${version}.tar.gz";
      sha256 = "0ap7nqrl5yi300j27k5l76zf3z6b8n0wvn6bcn6j3p0cmn8xs6s2";
    };
    patches = [ ./package.patch ];
  };

  yarnComponents = mkYarnPackage rec {
    src = source + "/js";
  };

  # bowerNix = pkgs.stdenv.mkDerivation rec {
  #   name = "nextcloud-calendar-bower-expression";
  #   src = source + "/js";
  #   buildInputs = with pkgs; [ nodePackages.bower2nix ];
  #   buildPhase = ''
  #     bower2nix bower.json nextcloud-calendar-bower.nix
  #   '';
  #   installPhase = ''
  #     mkdir -p $out
  #     cp nextcloud-calendar-bower.nix $out/
  #   '';
  # };

in pkgs.stdenv.mkDerivation rec {

  name = "${pname}-${version}";
  pname = "nextcloud-calendar";
  version = "1.5.6";
  src = source;

  buildInputs = with pkgs; [ which yarn nodejs nodePackages.gulp ];

  bowerComponents = pkgs.buildBowerComponents {
    name = "bower-components";
    # The file bower.nix is generated with nodePackages.bower2nix in calendar
    # repo js directory. Modify js/bower.json file so that URLs pointing to
    # GitHub are in format username/repo#hash or hash
    generated = ./bower.nix; #bowerNix;
    src = source + "/js";
  };

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
