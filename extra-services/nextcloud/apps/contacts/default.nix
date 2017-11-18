{lib, pkgs, ...}:

# Some notes on how this was set up:
#
# Checkout the contacts repo locally. Modify package.json so that all
# devDependencies are moved under dependencies. Run node2nix in the repo. Copy
# node-env.nix, node-packages.nix and packages.nix here. Also, copy default.nix
# as contacts.nix here.

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

  # Currently, contacts requires that variables.scss is copied from Nextcloud>11
  # in order to support Nextcloud 11. Makefile uses curl for that if the file
  # hasn't been already copied. So, let's copy it ourselves. If Contacts removes
  # this step from the Makefile, we can remove nextcloud as a build input and
  # remove the corresponding cp command from build phase..
  buildInputs = with pkgs; [
    which nodejs nodePackages.gulp
    nextcloud
  ];

  buildPhase = ''
    ln -s ${shell.nodeDependencies}/lib/node_modules
    mkdir -p build/css
    cp ${pkgs.nextcloud}/core/css/variables.scss build/css/
    make build
    make appstore
  '';

  installPhase = ''
    mkdir $out
    tar xvzf build/artifacts/appstore/contacts-*.tar.gz -C $out/
    mv $out/contacts* $out/contacts
  '';

}
