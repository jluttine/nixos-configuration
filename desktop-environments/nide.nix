{ config, pkgs, lib, ... }:

let
  cfg = config.localConfiguration;
  nide = builtins.fetchTarball "https://github.com/jluttine/NiDE/archive/master.tar.gz";
in
{

  imports = [
    "${nide}/nix/configuration.nix"
  ];

  config = lib.mkIf (cfg.desktopEnvironment == "nide") {

    services.xserver.desktopManager.nide = {
      enable = true;
      installPackages = false;
    };

    # Do not cache when fetching tarballs without sha256. Then, NiDE tarball
    # will always be fetched, it isn't cached for 1h.
    nix.extraOptions = ''
      tarball-ttl = 0
    '';

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

    environment.systemPackages = with pkgs; [

      # File manager
      dolphin
      kdeApplications.dolphin-plugins

      # Archives (e.g., tar.gz and zip)
      ark

      # GPG manager for KDE
      kgpg

      # Screenshots
      kdeApplications.spectacle

      # Bluetooth
      bluedevil

      # Text editor
      kate

      # Connect desktop and phone
      kdeconnect

      # Printing and scanning
      kdeApplications.print-manager
      simple-scan

      # Document readers
      okular

      # Browsers
      firefox
      chromium

      # Email
      thunderbird

      # Office suit
      libreoffice

      # Photo/image editor
      gwenview
      digikam5
      gimp-with-plugins
      # Gimp requires this, see: https://github.com/NixOS/nixpkgs/issues/60918
      #gnome3.gnome-themes-extra

      # Media player
      vlc

      # For GNOME Keyring to work for git https protocol, use git-credential-libsecret:
      #
      #   git config --global credential-helper /run/current-system/sw/bin/git-credential-libsecret
      #
      # That binary is included in gitFull.
      gitAndTools.gitFull

      # Choose some icon theme
      gnome3.adwaita-icon-theme
      maia-icon-theme
      # Not sure if this is needed:
      hicolor-icon-theme

    ];

  };

}
