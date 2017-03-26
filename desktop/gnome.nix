# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  # Bluetooth
  hardware.bluetooth.enable = true;

  services.xserver.enable = true;

  services.xserver.synaptics.enable = true;
  services.xserver.synaptics.twoFingerScroll = true;

  services.xserver.desktopManager.gnome3.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  services.printing.enable = true;

  hardware.pulseaudio.enable = true;

  # Add support for GConf (GNOME applications). See:
  # https://nixos.org/wiki/Solve_GConf_errors_when_running_GNOME_applications
  # services.dbus.packages = [ pkgs.gnome3.gconf ];
  # environment.pathsToLink = [ "/etc/gconf" ];

  environment.systemPackages = with pkgs; [
 
    # Bluetooth
    #bluez
    bluedevil

    # Text editors
    vim
    emacs
    kate

    # File format conversions
    pandoc
    pdf2svg

    # Drop-down terminal
    guake

    # Sound control
    pavucontrol


    # Document readers
    okular
    calibre

    sshfsFuse
    gnome3.gnome-disk-utility

    #owncloudclient
    #transmission_gtk

    # Browsers
    firefox
    chromium

    # Email
    #plasma5.applications
    #kmail
    thunderbird

    gnupg
    libreoffice
    scribus

    # Bitcoin
    electrum
    zbar

    # Photo manager
    digikam5
    #shotwell

    # Telegram
    cutegram
    linphone
    pybitmessage

    # OpenStreetMap editor
    josm

    #mythtv

    # 3D modelling
    blender

    # Photo/image editor
    gwenview
    gimp
    gimpPlugins.resynthesizer
    gimpPlugins.ufraw

    # Panorama stitcher
    hugin
    inkscape
    vlc

    # Haskell
    ghc
    stack

    octave
    R
 
    #gnome3.networkmanager_openvpn
    #gnome3.networkmanager_openconnect
    #gnome3.networkmanager_pptp
    #gnome3.gconf
    
    mkpasswd

    # Android
    jmtpfs
    gphoto2
    libmtp
    mtpfs

  ];
}
