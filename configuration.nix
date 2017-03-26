# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./version
      ./hostname
      ./system
      ./users
      ./desktop
      ./extra-apps
      ./extra-services
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Manual upgrades
  system.autoUpgrade.enable = false;

  # Immutable users and groups
  users.mutableUsers = false;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Hardware
  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = true;

  # Printing
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
  };

  # Fonts
  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      #corefonts # Microsoft free fonts
      inconsolata # monospaced
      unifont # some international languages
      font-awesome-ttf
      freefont_ttf
      opensans-ttf
      liberation_ttf
      ttf_bitstream_vera
      libertine
      ubuntu_font_family
      gentium
      symbola
    ];
  };

  # Fundamental core packages
  environment.systemPackages = with pkgs; [
 
    # Basic command line tools
    bash
    git
    hdf5
    zip

    # Text editors
    vim

    # VPN
    pptp
    openvpn

    # File format conversions
    pandoc
    pdf2svg

    # Screen brightness and temperature
    redshift

    # SSH filesystem
    sshfsFuse

    # Encryption key management
    gnupg

    # Yet another dotfile manager
    yadm
    gnupg1orig

    # Password hash generator
    mkpasswd

    # Android
    jmtpfs
    gphoto2
    libmtp
    mtpfs

    nix-prefetch-git

  ];

}
