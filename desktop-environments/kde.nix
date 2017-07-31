{ config, pkgs, lib, ... }:

let
  cfg = config.localConfiguration;
in lib.mkIf (cfg.desktopEnvironment == "kde")
{

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

  # Use Plasma 5
  services.xserver.desktopManager.plasma5.enable = true;

  environment.systemPackages = with pkgs; [

    # Password manager for KDE
    kdeFrameworks.kwallet
    kdeApplications.kwalletmanager

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
    pinentry_qt5

    kdeplasma-addons

    # Screenshots
    kdeApplications.spectacle

    # Bluetooth
    bluedevil

    # Text editor
    kate

    # Torrenting
    ktorrent

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
    libreoffice
    scribus

    # Vector graphics
    inkscape

    # Photo/image editor
    gwenview
    gimp
    #gimpPlugins.resynthesizer
    #gimpPlugins.ufraw
    digikam5

    # Media player
    vlc

    # KDE apps
    kdeFrameworks.kconfig
    kdeFrameworks.kconfigwidgets
    konsole
    dolphin
    kdeApplications.dolphin-plugins

  ];
}
