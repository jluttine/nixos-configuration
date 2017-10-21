# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ./desktop-environments
    ./extra-services
  ];

  # Local configuration options
  options.localConfiguration = with lib; {
    hostName = mkOption {
      type = types.str;
      default = "nixos";
    };
    grubDevice = mkOption {
      type = types.str;
    };
    version = mkOption {
      type = types.str;
      default = "17.03";
    };
    users = mkOption {
      type = types.listOf types.attrs;
    };
    displayManager = mkOption {
      type = types.enum [ "lightdm" "sddm" ];
      default = "lightdm";
    };
    desktopEnvironment = mkOption {
      type = types.enum [ "kde" ];
      default = "kde";
    };
    allowUnfree = mkOption {
      type = types.bool;
      default = false;
    };
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
    };
    nixpkgs = mkOption {
      type = types.nullOr types.path;
      default = null;
    };
  };

  config = let

    localConfiguration = (import ./local-configuration.nix) {
      inherit pkgs;
      users = import ./users.nix;
    };

    cfg = config.localConfiguration;

  in {

      nix = (
        if cfg.nixpkgs == null
        then {}
        else {
          nixPath = [
            "nixpkgs=${cfg.nixpkgs}"
            "nixos-config=/etc/nixos/configuration.nix"
          ];
          useSandbox = true;
        }
      );

      # This enables type checking
      localConfiguration = localConfiguration;

      # Use the GRUB 2 boot loader.
      boot.loader.grub = {
        enable = true;
        version = 2;
        device = cfg.grubDevice;
      };

      # Splash screen at boot time
      boot.plymouth.enable = false;

      # fileSystems = cfg.fileSystems;
      # boot.initrd.luks.devices = cfg.luksDevices;

      # Set your time zone.
      time.timeZone = "Europe/Helsinki";

      # Manual upgrades
      system.autoUpgrade.enable = false;

      # Immutable users and groups
      users.mutableUsers = false;
      users.users = let
        getUserAttrs = userCfg: {
          name = userCfg.username;
          value = userCfg.user;
        };
      in builtins.listToAttrs (map getUserAttrs cfg.users);
      users.groups = let
        getGroupAttrs = userCfg: {
          name = userCfg.username;
          value = userCfg.group;
        };
      in builtins.listToAttrs (map getGroupAttrs cfg.users);

      # Networking
      networking = {
        hostName = cfg.hostName;
        networkmanager.enable = true;
        firewall = {
          enable = true;
          # Enable PPTP VPN
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
        bluetooth.enable = true;
        pulseaudio.enable = true;
        sane = {
          enable = true;
          #extraBackends = [ pkgs.hplipWithPlugin ];
        };
        #opengl.enable = true;
      };

      services = {
        # Printing
        printing = {
          enable = true;
          webInterface = true;
          gutenprint = true;
        };
        avahi = {
          enable = true;
          nssmdns = true;
        };
        # Graphical environment (X server)
        xserver = {
          enable = true;
          displayManager."${cfg.displayManager}".enable = true;
          synaptics = {
            enable = true;
            twoFingerScroll = true;
          };
        };
        # Automatic device mounting daemon
        devmon.enable = true;
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
          source-code-pro
          freefont_ttf
          opensans-ttf
          liberation_ttf
          liberationsansnarrow
          ttf_bitstream_vera
          libertine
          ubuntu_font_family
          gentium
          symbola
        ];
      };

      nixpkgs.config.allowUnfree = cfg.allowUnfree;

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
        nix-repl
        yle-dl

        # Gamin: a file and directory monitoring system
        fam

        # Basic image manipulation and handling stuff
        imagemagick
        ghostscript

        # Text editors
        vim
        neovim
        xclip  # system clipboard support for vim

        owncloud-client

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

        # Make NTFS filesystems (e.g., USB drives)
        ntfs3g

        # Encrypted USB sticks etc
        cryptsetup

        # GUI for sound control
        pavucontrol

        python3Packages.magic-wormhole

      ] ++ cfg.extraPackages;

    }

  ;

}
