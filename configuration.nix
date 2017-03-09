# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./system.nix
      ./users.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # system.autoUpgrade.enable = true;

  services.xserver.enable = true;

  services.xserver.desktopManager.gnome3.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  #services.xserver.windowManager.i3.enable = true;

  services.printing.enable = true;

  hardware.pulseaudio.enable = true;

  # Immutable users and groups
  users.mutableUsers = false;

  # The NixOS release to be compatible with for stateful data such as databases.
  #system.stateVersion = "16.03";
  system.stateVersion = "unstable";

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

  users.users = {
    root = {
      isNormalUser = false;
    };
    jluttine = {
      description = "Jaakko Luttinen";
      home = "/home/jluttine";
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "networkmanager" ];
    };
  };

  # Add support for GConf (GNOME applications). See:
  # https://nixos.org/wiki/Solve_GConf_errors_when_running_GNOME_applications
  # services.dbus.packages = [ pkgs.gnome3.gconf ];
  # environment.pathsToLink = [ "/etc/gconf" ];

  environment.systemPackages = with pkgs; [
    git
    bash
    hdf5

    pandoc
    pdf2svg
    zip

    guake
    redshift
    pavucontrol

    simple-scan

    sshfsFuse
    gnome3.gnome-disk-utility

    #owncloudclient
    transmission_gtk

    vim
    emacs

    firefox
    thunderbird
    gnupg
    libreoffice
    scribus

    electrum
    zbar

    cutegram
    linphone
    pybitmessage

    josm

    #mythtv

    blender
    gimp
    gimpPlugins.resynthesizer
    gimpPlugins.ufraw
    shotwell
    hugin
    inkscape
    vlc

    python35
    python35Packages.numpy
    python35Packages.scipy
    #python35Packages.matplotlib
    #python35Packages.jupyter
    #python35Packages.h5py
    #python35Packages.pandas
    #python35Packages.sphinx
    #python35Packages.sphinx_rtd_theme
    #python35Packages.nose
    python35Packages.virtualenv
    #python35Packages.virtualenvwrapper
    #python35Packages.youtube-dl

    octave
    R

    #texLive
    #texLiveExtra
    #texLiveFull
    #texLiveBeamer

    gnome3.networkmanager_openvpn
    gnome3.networkmanager_openconnect
    gnome3.networkmanager_pptp
    #gnome3.gconf
    
    yadm
    gnupg1orig

    # i3
    #i3status
    #dmenu

    mkpasswd

    nix-prefetch-git

  ];
}
