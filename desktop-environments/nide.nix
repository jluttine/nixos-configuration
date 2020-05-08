{ config, pkgs, lib, ... }:

let
  cfg = config.localConfiguration;
in
{

  config = lib.mkIf (cfg.desktopEnvironment == "nide") {
    # Open ports for KDE Connect
    networking.firewall.allowedTCPPorts = [
                          1714 1715 1716 1717 1718 1719
      1720 1721 1722 1723 1724 1725 1726 1727 1728 1729
      1730 1731 1732 1733 1734 1735 1736 1737 1738 1739
      1740 1741 1742 1743 1744 1745 1746 1747 1748 1749
      1750 1751 1752 1753 1754 1755 1756 1757 1758 1759
      1760 1761 1762 1763 1764
    ];
    networking.firewall.allowedUDPPorts = [
                          1714 1715 1716 1717 1718 1719
      1720 1721 1722 1723 1724 1725 1726 1727 1728 1729
      1730 1731 1732 1733 1734 1735 1736 1737 1738 1739
      1740 1741 1742 1743 1744 1745 1746 1747 1748 1749
      1750 1751 1752 1753 1754 1755 1756 1757 1758 1759
      1760 1761 1762 1763 1764
    ];

    # Use none (i.e., xterm as the desktop manager)
    services.xserver.desktopManager.xterm.enable = true;
    services.xserver.displayManager.defaultSession = "xterm";

    # Add DejaVu font and same fonts as Plasma
    fonts.fonts = with pkgs; [
      jetbrains-mono
      dejavu_fonts
      noto-fonts
      hack-font
      (nerdfonts.override {fonts=["Iosevka"];})
    ];

    # In order to set the default font for Simple Terminal, one has to patch
    # this line: https://git.suckless.org/st/file/config.def.h.html#l8
    #
    # Or, alternatively, wrap st so that it is always called with -f flag. But
    # then one cannot call st with another font flag.. Wait, yes they can! The
    # last -f flag is used so one can override the previous options. Nice.

    # These are the same fonts as Plasma uses
    fonts.fontconfig.defaultFonts = {
      monospace = [ "JetBrains Mono" ]; #"Hack" "Noto Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };

    # environment.variables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";

    nixpkgs.overlays = [
      (
        self: super: {
          polybar = super.polybar.override {
            i3Support = true;
            #mpdSupport = true;
            pulseSupport = true;
            #githubSupport = true;
            nlSupport = false;
            iwSupport = true;
            wirelesstools = pkgs.wirelesstools;
          };
        }
      )
      (
        # See: https://github.com/yshui/picom/issues/306
        #
        # Should be fixed in more recent versions than 7.5.
        self: super: {
          picom = (
            super.picom.overrideAttrs (oldAttrs: {
              src = pkgs.fetchFromGitHub {
                owner = "yshui";
                repo = "picom";
                # See #306
                # rev = "17831a7be3ecf02b874738009fbb2e244de6bd67";
                # sha256 = "12c43xzvwbvn8bfmymd1798c7ayc7jhzl09h4628zv5krsk8crb3";
                # See #381
                rev = "d1f4969fc1efed4af5bd06ba86fdd11624e60a63";
                sha256 = "1wxx63271bxrcnhylxcb2y770j0ibdzp8v16hhljdc1mp7723jbw";
              };
            })
          );
          #).override { debug = true; };
        }
      )
      (
        # KBDD doesn't work if it is started without a window in focus. It'll
        # not detect EWMH support and fallback to some generic mode that doesn't
        # remember the layout of the windows.. This patch just forces it to
        # believe there is always EWMH support whether it can detect it or not.
        # A better solution could be that KBDD would have a global state
        # keyboard layout which is used when no window is focused.
        #
        # TODO: Add global (no window in focus) keyboard layout state.
        self: super: {
          kbdd = super.kbdd.overrideAttrs (oldAttrs: {
            patches = [ ./kbdd.patch ];
          });
        }
      )
    ];
    # Keybindings for adjusting monitor brightness. Adjusting brightness with
    # actkbd+light is nice because it's independent of X and works in ttys.
    services.actkbd = {
      enable = true;
      bindings = let
        light = "${pkgs.light}/bin/light";
        step = "10";
      in [
        {
          keys = [ 224 ];
          events = [ "key" ];
          # Use minimum brightness 0.1 so the display won't go totally black.
          command = "${light} -N 0.1 && ${light} -U ${step}";
        }
        {
          keys = [ 225 ];
          events = [ "key" ];
          command = "${light} -A ${step}";
        }
      ];
    };

    # Enable users to modify brightness. NOTE: User must belong to video group!
    # (These modify udev rules, so if you just enabled this, probably best to
    # reboot.)
    programs.light.enable = true;
    hardware.acpilight.enable = true;

    environment.systemPackages = with pkgs; [

      # NiDE requirements
      i3
      (rofi.override { plugins = [ rofi-file-browser ]; } )
      # (rofi.override { configDir = "/tmp/rofi/"; })
      #(rofi.override { configDir = "/home/jluttine/rofi-tmp/"; })
      polybar
      dunst
      dex
      st
      kbdd
      gnome3.networkmanagerapplet
      xss-lock
      vlock
      xsecurelock
      xidlehook
      picom
      hsetroot  # picom-supported replacement for xsetroot


      #
      # Other minimal stuff
      #

      sxiv
      mupdf
      trash-cli
      vimb
      surf
      qutebrowser
      luakit
      dolphin
      arandr

      # Password manager for KDE
      # kdeFrameworks.kwallet
      # kdeApplications.kwalletmanager
      # kwalletcli

      # Allow automatic unlocking of kwallet if the same password. This seems to
      # work without installing kwallet-pam.
      #kwallet-pam

      # ssh-add prompts a user for a passphrase using KDE. Not sure if it is used
      # by anything? ssh-add just asks passphrase on the console.
      #ksshaskpass

      # Archives (e.g., tar.gz and zip)
      ark

      # GPG manager for KDE
      kgpg
      # This is needed for graphical dialogs used to enter GPG passphrases
      # pinentry_qt5

      # kdeplasma-addons

      # Screenshots
      kdeApplications.spectacle

      # Bluetooth
      bluedevil

      # Text editor
      kate

      # Torrenting
      #ktorrent

      # Connect desktop and phone
      kdeconnect

      # Drop-down terminal
      yakuake

      # Printing and scanning
      kdeApplications.print-manager
      simple-scan

      # Document readers
      okular

      # Browsers
      firefox
      chromium

      # Email
      #kmail
      thunderbird

      # Office suit
      #libreoffice

      # Photo/image editor
      gwenview
      digikam5
      gimp-with-plugins
      # Gimp requires this, see: https://github.com/NixOS/nixpkgs/issues/60918
      #gnome3.gnome-themes-extra

      # Media player
      vlc

      # KDE apps
      # kdeFrameworks.kconfig
      # kdeFrameworks.kconfigwidgets
      # konsole
      dolphin
      kdeApplications.dolphin-plugins

      # Perhaps not needed, but might be nice for managing..
      gnome3.seahorse
      # kdeApplications.kwalletmanager

      # Not sure if needed here in systemPackages..?
      # kdeFrameworks.kwallet
      # libsForQt5.kwallet
      # kwallet-pam

      # In order to user Kwallet to store the passphrases, set the following in
      # ~/.gnupg/gpg-agent.conf:
      #
      #   pinentry-program /run/current-system/sw/bin/pinentry-kwallet
      #
      # Then, gpg-agent will use Kwallet to ask the passphrases.
      #
      # However, I tried to use Kwallet but it didn't store the passphrase but
      # "yes" string instead. Some bug somewhere? Well, it's also possible to
      # use GNOME Keyring to store the passphrases by setting:
      #
      #   pinentry-program /run/current-system/sw/bin/pinentry-gnome3
      #
      # in ~/.gnupg/gpg-agent.conf. This seems to store the passphrases
      # correctly.
      gnupg
      pinentry_gnome # contains pinentry-gnome3
      pinentry-qt
      pinentry
      keychain
      # kwalletcli     # contains pinentry-kwallet

      # For GNOME Keyring to work for git https protocol, use git-credential-libsecret:
      #
      #   git config --global credential-helper /run/current-system/sw/bin/git-credential-libsecret
      #
      # That binary is included in gitFull.
      gitAndTools.gitFull
    ];

  };

}
