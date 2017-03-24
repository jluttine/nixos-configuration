# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./version
      ./hostname
      ./system
      ./users
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;

  networking.networkmanager.enable = true;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    # KDE Connect ports
                        1714 1715 1716 1717 1718 1719
    1720 1721 1722 1723 1724 1725 1726 1727 1728 1729
    1730 1731 1732 1733 1734 1735 1736 1737 1738 1739
    1740 1741 1742 1743 1744 1745 1746 1747 1748 1749
    1750 1751 1752 1753 1754 1755 1756 1757 1758 1759
    1760 1761 1762 1763 1764
  ];
  networking.firewall.allowedUDPPorts = [
    # KDE Connect ports
                        1714 1715 1716 1717 1718 1719
    1720 1721 1722 1723 1724 1725 1726 1727 1728 1729
    1730 1731 1732 1733 1734 1735 1736 1737 1738 1739
    1740 1741 1742 1743 1744 1745 1746 1747 1748 1749
    1750 1751 1752 1753 1754 1755 1756 1757 1758 1759
    1760 1761 1762 1763 1764
  ];

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # system.autoUpgrade.enable = true;

  services.xserver.enable = true;

  services.xserver.synaptics.enable = true;
  services.xserver.synaptics.twoFingerScroll = true;

  #services.xserver.desktopManager.gnome3.enable = true;
  #services.xserver.displayManager.gdm.enable = true;
  #services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.printing.enable = true;

  hardware.pulseaudio.enable = true;

  # Backlight configuration CLI tool
  programs.light.enable = true;

  # Immutable users and groups
  users.mutableUsers = false;

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

  # Add support for GConf (GNOME applications). See:
  # https://nixos.org/wiki/Solve_GConf_errors_when_running_GNOME_applications
  # services.dbus.packages = [ pkgs.gnome3.gconf ];
  # environment.pathsToLink = [ "/etc/gconf" ];

  environment.systemPackages = with pkgs; [
 
    # Required for networkmanager + i3
    #gnome3.dconf

    #plasma5.plasma-workspace

    # Zotero
    #zotero # broken atm

    # Web camera
    fswebcam

    # Password manager for KDE
    kdeFrameworks.kwallet
    kwallet-pam
    kdeApplications.kwalletmanager
    ksshaskpass
    kgpg

    # Bluetooth
    #bluez
    bluedevil

    # Basic command line tools
    bash
    git
    hdf5
    zip

    # Text editors
    vim
    emacs
    kate
    #plasma5.kwrited

    # Archiving
    #plasma5.ark # unfree

    # MPD client
    cantata

    # Torrents
    ktorrent

    # VPN
    pptp
    openvpn

    # File format conversions
    pandoc
    pdf2svg

    # Games
    #plasma5.kigo
    
    # Connect desktop and phone
    kdeconnect

    # Drop-down terminal
    #guake
    yakuake

    # Screen brightness and temperature
    xorg.xbacklight
    redshift

    # Sound control
    pavucontrol

    # Printing and scanning
    gutenprint
    cups
    kdeApplications.print-manager
    simple-scan

    # Document readers
    okular
    calibre

    sshfsFuse
    #gnome3.gnome-disk-utility

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

    # rxvt-unicode terminal
    #rxvt_unicode
    #urxvt_perls

    # TensorFlow build dependencies
    bazel
    swig

    # Binay TensorFlow..
    #python35Packages.tensorflow
    
    # Haskell
    ghc
    stack

    haskellPackages.hmatrix

    # hyper-haskell ?
    # haskell-tensorflow ?

    octave
    R

    #texLive
    #texLiveExtra
    #texLiveFull
    #texLiveBeamer

    #gnome3.networkmanager_openvpn
    #gnome3.networkmanager_openconnect
    #gnome3.networkmanager_pptp
    #gnome3.gconf
    
    yadm
    gnupg1orig

    # i3
    #i3status
    #dmenu
    #networkmanager
    #networkmanagerapplet
    #i3blocks
    # Adjust backlight brightness
    #xorg.xbacklight
    # PulseAudio volume control
    #pavucontrol
    #nm-applet
    # Or sway instead? i3 for wayland
    # Perhaps not yet.. Not all apps in NixOS support Wayland yet.
    #sway
    
    # KDE apps
    kdeFrameworks.kconfig
    kdeFrameworks.kconfigwidgets
    konsole
    dolphin
    kdeApplications.dolphin-plugins
    
    bc

    mkpasswd

    # Android
    jmtpfs
    gphoto2
    libmtp
    mtpfs


    # File manager
    #pcmanfm
    #kde4.krusader

    nix-prefetch-git

  ];
}
