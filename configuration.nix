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
      type = types.enum [ "kde" "gnome" "nide" ];
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
      type = types.nullOr types.str;
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
      nix = {
        useSandbox = true;
        # See: https://github.com/nix-community/nix-direnv#usage
        extraOptions = ''
          keep-derivations = true
          keep-outputs = true
        '';
      } // lib.optionalAttrs (cfg.nixpkgs != null) {
        nixPath = [
          "nixpkgs=${cfg.nixpkgs}"
          "nixos-config=/etc/nixos/configuration.nix"
        ];
      };

      # This enables type checking
      localConfiguration = localConfiguration;

      # Use the GRUB 2 boot loader.
      boot = {

        kernelModules = [ "nf_conntrack_pptp" ];

        loader.grub = {
          enable = true;
          version = 2;
          device = cfg.grubDevice;
        };

        # Splash screen at boot time
        plymouth.enable = false;

        cleanTmpDir = true;

      };

      # fileSystems = cfg.fileSystems;
      # boot.initrd.luks.devices = cfg.luksDevices;

      # Set your time zone.
      time.timeZone = "Europe/Helsinki";

      # Manual upgrades
      system.autoUpgrade.enable = false;

      # NOTE: This is something you should probably never change. It's not
      # really related to NixOS version. It just prevents some backwards
      # incompatible changes from happening. Grep nixpkgs for "stateVersion" to
      # see how it's used. Basically, when some default setting value is
      # modified, this version number is used to check whether you are using the
      # old or new default, so your system won't break if, for instance, a
      # database changes its default data directory.
      system.stateVersion = "18.03";

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
        pulseaudio.enable = true;
        sane = {
          enable = true;
          #extraBackends = [ pkgs.hplipWithPlugin ];
        };
        #opengl.enable = true;
        firmware = [
          pkgs.openelec-dvb-firmware
        ];
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
          displayManager."${cfg.displayManager}".enable = true;
          libinput = {
            enable = true; # or should this be used instead of synaptics??
          };
          synaptics = {
            enable = false;
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

      nixpkgs.config.allowUnfree = cfg.allowUnfree;

      # Add a udev rule to grant all users access to the Polar V800 USB device
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="0da4", ATTRS{idProduct}=="0008", MODE="0666"
      '';

      # TEMPORARY FIX UNTIL PR MERGED: https://github.com/NixOS/nixpkgs/pull/77811
      nixpkgs.overlays = [
        (
          self: super: {
            yle-dl = super.yle-dl.overrideAttrs (oldAttrs: {
              propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
                pkgs.pythonPackages.setuptools
              ];
            });
          }
        )
      ];

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

        # Gamin: a file and directory monitoring system
        fam

        # Basic image manipulation and handling stuff
        imagemagick
        ghostscript

        # Simple PDF
        mupdf

        # Text editors
        vim
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

        python3Packages.magic-wormhole

      ] ++ cfg.extraPackages;

    }

  ;

}
