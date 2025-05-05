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

  nix.settings = {
    sandbox = true;
    # See: https://github.com/nix-community/nix-direnv#usage
    #
    # Also, do not cache when fetching tarballs without sha256. Then, NiDE
    # tarball will always be fetched, it isn't cached for 1h.
    keep-derivations = true;
    keep-outputs = true;
    tarball-ttl = 0;
  };
  nixpkgs.overlays = [
     (
       self: super: {
         # See: https://github.com/NixOS/nixpkgs/pull/367290#issuecomment-2665002770
         vlc = super.vlc.overrideAttrs (
           oldAttrs: {
             patches = oldAttrs.patches ++ [(super.fetchpatch {
               name = "vlc-vaapi-with-latest-ffmpeg.patch";
               url = "https://code.videolan.org/videolan/vlc/-/commit/ba5dc03aecc1d96f81b76838f845ebde7348cf62.patch";
               sha256 = "sha256-s6AI9O0V3AKOyw9LbQ9CgjaCi5m5+nLacKNLl5ZLC6Q=";
             })];
           }
         );
       }
     )
  ];

  # Use the GRUB 2 boot loader.
  boot = {

    #kernelModules = [ "nf_conntrack_pptp" ];

    # UEFI systems
    loader.systemd-boot = {
      editor = false;
    };

    tmp.cleanOnBoot = true;

  };

  # Accept the license for ADB just in case one enables it.
  nixpkgs.config.android_sdk.accept_license = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Locale
  i18n = {
    defaultLocale = "en_DK.UTF-8";
    extraLocaleSettings = {
      LC_MONETARY = "fi_FI.UTF-8"; 
      LC_TIME = "en_GB.UTF-8";
    };
  };

  # Manual upgrades
  system.autoUpgrade.enable = false;

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Enable PPTP VPN
      #autoLoadConntrackHelpers = true;
      #connectionTrackingModules = [ "pptp" ];
      #autoLoadConntrackHelpers = true;
      extraCommands = ''
        iptables -A INPUT -p 47 -j ACCEPT
        iptables -A OUTPUT -p 47 -j ACCEPT
      '';
    };
  };

  # Source: https://nixos.wiki/wiki/Accelerated_Video_Playback
  #nixpkgs.config.packageOverrides = pkgs: {
  #  vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  #};
  # Hardware
  hardware = {
    # Source: https://nixos.wiki/wiki/Accelerated_Video_Playback
    graphics = {
      enable = true;
      # VLC hardware decoding broken atm. See: https://github.com/NixOS/nixpkgs/pull/367290
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        #vaapiIntel
        #vaapiVdpau
        #libvdpau-va-gl
      ];
    };
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
      pkgs.libreelec-dvb-firmware
    ];
    bluetooth = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.bluez;
    };
  };

  services = {
    pipewire.enable = false;
    # Printing
    printing = {
      enable = true;
      webInterface = true;
      drivers = with pkgs; [ gutenprint ];
    };
    avahi = {
      enable = false;
    };
    # Browsed has security issues, disable it.
    printing.browsed.enable = lib.mkForce false;
    libinput = {
      enable = true; # or should this be used instead of synaptics??
      touchpad = {
        tapping = false;
        disableWhileTyping = true;
      };
    };
    # Graphical environment (X server)
    xserver = {
      enable = true;
      synaptics = {
        enable = false;
        twoFingerScroll = true;
      };
    };
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
    packages = with pkgs; [
      #corefonts # Microsoft free fonts
      inconsolata # monospaced
      unifont # some international languages
      font-awesome
      freefont_ttf
      open-sans
      liberation_ttf
      liberation-sans-narrow
      ttf_bitstream_vera
      libertine
      ubuntu_font_family
      gentium
      # Good monospace fonts
      source-code-pro
    ];
  };

  security.acme = {
    defaults.email = "jaakko.luttinen@iki.fi";
    acceptTerms = true;
  };

  # Add a udev rule to grant all users access to the Polar V800 USB device
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="0da4", ATTRS{idProduct}=="0008", MODE="0666"
  '';

  programs.ssh.knownHosts = {
    "kapsi.fi" = {
      extraHostNames = [ "kapsi" ];
      publicKeyFile = ./pubkeys/kapsi.pub;
    };
  };

  # Add a convenient yadm alias for working with NixOS configs
  environment.interactiveShellInit = ''
    alias yadm-nixos='yadm --yadm-dir /etc/nixos/.yadm/config --yadm-data /etc/nixos/.yadm/data'
  '';

  # Fundamental core packages
  environment.systemPackages = with pkgs; [

    # Basic command line tools
    bash
    wget
    file
    git
    hdf5
    zip
    unzip
    htop
    yle-dl
    yt-dlp
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
    pciutils
    wirelesstools
    busybox
    nix-prefetch-github

    # Gamin: a file and directory monitoring system
    #fam

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
    sshfs-fuse

    # Encryption key management
    gnupg

    # Yet another dotfile manager
    yadm

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
    mpv

    # Office suit
    libreoffice

    # Printing and scanning
    simple-scan

    # Document readers
    okular

    # Photo/image editor
    gwenview
    digikam
    gimp-with-plugins

    # Archives (e.g., tar.gz and zip)
    ark

    # Screenshots
    spectacle

    # Bluetooth
    bluedevil

    jellyfin-media-player

    pdftk

  ];

}
