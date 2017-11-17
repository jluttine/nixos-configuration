{lib, pkgs, ...}:

#let

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
#in (import ./contacts.nix { inherit pkgs; }).package

let
  shell = (import ./contacts.nix {}).shell;
in pkgs.stdenv.mkDerivation rec {
  name = "${pname}-${version}";
  pname = "contacts";
  version = "2.0.0";
  # NOTE: Don't use 2.0.0 release because they dropped Bower after that. Let's
  # use a real release whenever that comes without Bower.
  src = pkgs.fetchFromGitHub {
    owner = "nextcloud";
    repo = "contacts";
    rev = "df90c7c";
    sha256 = "0hmaq6mx3d3q8kxnijcqp798yzgslfdm06px1qw4dg11q63c284g";
  };
  # src = pkgs.fetchzip {
  #   url = "https://github.com/nextcloud/${pname}/archive/${version}.tar.gz";
  #   sha256 = "02a27iwf3jp8cw0x81k782m4jq6d79knpwflc0phyawnvs8zp3n6";
  # };

  patches = [ ./package.patch ];

  buildInputs = with pkgs; [ which nodejs nodePackages.gulp ];
  #buildInputs = with pkgs; [ which yarn nodejs nodePackages.gulp ];

  buildPhase = ''
    export NODE_PATH=${shell.nodeDependencies}/lib/node_modules
    echo $NODE_PATH
    export HOME=$(pwd)
    make build
    make appstore
  '';

  installPhase = ''
    mkdir -p $out/contacts
    cp -R build/appstore/contacts/* $out/contacts/
  '';

}
