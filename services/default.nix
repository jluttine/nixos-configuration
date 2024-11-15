# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./nginx.nix
      ./emacs.nix
      ./tuhlaajapojat
      ./tv.nix
      ./media.nix
      ./printserver.nix
      ./weechat.nix
      ./radicale.nix
      ./tt-rss.nix
      ./diskrsync.nix
      ./mpd.nix
      ./empty-domain.nix
      ./salmon.nix
      ./syncthing.nix
      ./bayesleague
      ./matrix.nix
    ];
}
