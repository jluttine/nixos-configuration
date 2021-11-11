# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{

  imports = let
    nide = builtins.fetchTarball "https://github.com/jluttine/NiDE/archive/master.tar.gz";
  in [
    ./hardware-configuration.nix
    ./services
    ./programs
    ./users.nix
    "${nide}/nix/configuration.nix"
  ];

  nix = {
    useSandbox = true;
    # See: https://github.com/nix-community/nix-direnv#usage
    #
    # Also, do not cache when fetching tarballs without sha256. Then, NiDE
    # tarball will always be fetched, it isn't cached for 1h.
    extraOptions = ''
      keep-derivations = true
      keep-outputs = true
      tarball-ttl = 0
    '';
  };

  # Use the GRUB 2 boot loader.
  boot = {

    kernelModules = [ "nf_conntrack_pptp" ];

    # BIOS systems
    loader.grub = {
      version = 2;
    };
    # UEFI systems
    loader.systemd-boot = {
      editor = false;
    };
    # Splash screen at boot time
    plymouth.enable = false;

    cleanTmpDir = true;

  };

  # Accept the license for ADB just in case one enables it.
  nixpkgs.config.android_sdk.accept_license = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Manual upgrades
  system.autoUpgrade.enable = false;

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Enable PPTP VPN
      autoLoadConntrackHelpers = true;
      connectionTrackingModules = [ "pptp" ];
      #autoLoadConntrackHelpers = true;
      extraCommands = ''
        iptables -A INPUT -p 47 -j ACCEPT
        iptables -A OUTPUT -p 47 -j ACCEPT
      '';
    };
  };

  # Hardware
  hardware = {
    pulseaudio = {
      enable = true;
    } // (
      # NixOS allows either a lightweight build (default) or full build of
      # PulseAudio to be installed. Only the full build has Bluetooth support,
      # so it must be selected if bluetooth is enabled.
      if config.hardware.bluetooth.enable
      then { package = pkgs.pulseaudioFull; }
      else { }
    );
    sane.enable = true;
    firmware = [
      pkgs.openelec-dvb-firmware
    ];
    bluetooth = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.bluezFull;
    };
  };

  services = {
    # Printing
    printing = {
      enable = true;
      webInterface = true;
      drivers = with pkgs; [ gutenprint ];
    };
    avahi = {
      enable = true;
      nssmdns = true;
    };
    # Graphical environment (X server)
    xserver = {
      enable = true;
      libinput = {
        enable = true; # or should this be used instead of synaptics??
        touchpad.tapping = false;
      };
      synaptics = {
        enable = false;
        twoFingerScroll = true;
      };
    };
    # Set defaults for syncthing (but don't enable by default)
    syncthing.openDefaultPorts = lib.mkDefault true;
    # Automatic device mounting daemon
    devmon.enable = true;
    # Bluetooth stuff
  };

  # Fonts
  fonts = {
    fontDir = {
      enable = true;
    };
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      #corefonts # Microsoft free fonts
      inconsolata # monospaced
      unifont # some international languages
      font-awesome-ttf
      freefont_ttf
      opensans-ttf
      liberation_ttf
      liberationsansnarrow
      ttf_bitstream_vera
      libertine
      ubuntu_font_family
      gentium
      # Good monospace fonts
      jetbrains-mono
      source-code-pro
    ];
  };

  security.acme = {
    email = "jaakko.luttinen@iki.fi";
    acceptTerms = true;
  };

  # Add a udev rule to grant all users access to the Polar V800 USB device
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="0da4", ATTRS{idProduct}=="0008", MODE="0666"
  '';

  programs.ssh.knownHosts = {
    kapsi = {
      hostNames = [ "kapsi.fi" ];
      publicKeyFile = ./pubkeys/kapsi.pub;
    };
  };

  # Fundamental core packages
  environment.systemPackages = with pkgs; [

    # Basic command line tools
    bash
    wget
    file
    gksu
    git
    hdf5
    zip
    unzip
    htop
    yle-dl
    youtube-dl
    nix-index
    dnsutils
    whois
    coreutils
    vbetool
    killall
    nethogs
    binutils
    lsof
    usbutils
    tree

    # Gamin: a file and directory monitoring system
    fam

    # Basic image manipulation and handling stuff
    imagemagick
    ghostscript

    # Simple PDF
    mupdf

    # Text editors
    vim
    kate
    xclip  # system clipboard support for vim

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
    openssl

    # Android
    jmtpfs
    gphoto2
    libmtp
    mtpfs

    nix-prefetch-git

    # Make NTFS filesystems (e.g., USB drives)
    ntfs3g

    # Encrypted USB sticks etc
    cryptsetup

    # GPG password entry from the terminal
    pinentry

    # GUI for sound control
    pavucontrol

    # Trash management from the command line
    trash-cli

    # Simple and secure file sending
    python3Packages.magic-wormhole
    croc

    # Disk usage analysis
    filelight

    # Browsers
    firefox
    chromium

    # Email
    #kmail
    thunderbird

    vlc

    # Office suit
    libreoffice

    # Printing and scanning
    simple-scan

    # Document readers
    okular

    # Photo/image editor
    gwenview
    digikam5
    gimp-with-plugins

    # Archives (e.g., tar.gz and zip)
    ark

    # Screenshots
    spectacle

    # Bluetooth
    bluedevil

  ];

}
