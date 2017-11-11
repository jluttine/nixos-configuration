{lib, pkgs, ...}:

let

  # version = "2.0.0";
  # pname = "contacts";

  # source = pkgs.srcOnly {
  #   stdenv = pkgs.stdenv;
  #   name = pname;
  #   src = pkgs.fetchzip {
  #     url = "https://github.com/nextcloud/${pname}/archive/${version}.tar.gz";
  #     sha256 = "02a27iwf3jp8cw0x81k782m4jq6d79knpwflc0phyawnvs8zp3n6";
  #   };
  #   #patches = [ ./package.patch ];
  # };

  # yarnComponents = mkYarnPackage rec {
  #   src = source + "/js";
  # };

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


  # CHECK THIS OUT:
  # https://github.com/svanderburg/node2nix/issues/8#issuecomment-233465074
in (import ./contacts.nix { inherit pkgs; }).package



# in pkgs.stdenv.mkDerivation rec {

#   inherit pname version;

#   name = "nextcloud-${pname}-${version}";
#   src = source;

#   buildInputs = with pkgs; [ which yarn nodejs nodePackages.gulp ];

#   # bowerComponents = pkgs.buildBowerComponents {
#   #   name = "bower-components";
#   #   # The file bower.nix is generated with nodePackages.bower2nix in calendar
#   #   # repo js directory. Modify js/bower.json file so that URLs pointing to
#   #   # GitHub are in format username/repo#hash or hash
#   #   generated = ./bower.nix; #bowerNix;
#   #   src = source + "/js";
#   # };

#   buildPhase = ''
#     make
#   '';

#   installPhase = ''
#     mkdir -p $out/calendar
#     cp -R build/appstore/calendar/* $out/calendar/
#   '';
# }
