{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;

in {

  options = with lib; { };

  config = lib.mkIf cfg.enable {
    # Provides org.freedesktop.secrets:
    # - GNOME keyring
    # - Kwallet (maybe???)
    #
    # Should I use autostart or systemd service??
    #
    # I couldn't get Kwallet auto-unlock working.

    # Enable for all(?) display managers.
    security.pam.services = let
      keyring = "GnomeKeyring";
      #keyring = "Kwallet";
      enableKeyring = "${"enable" + keyring}";
    in {
      gdm."${enableKeyring}" = true;
      kdm."${enableKeyring}" = true;
      lightdm."${enableKeyring}" = true;
      sddm."${enableKeyring}" = true;
      slim."${enableKeyring}" = true;
    };

    services.gnome3.gnome-keyring.enable = true;

    # systemd.user.services.gnome-keyring = {
    #   description = "GNOME Keyring daemon";
    #   wantedBy = [ "graphical-session.target" ];
    #   partOf = [ "graphical-session.target" ];
    #   serviceConfig = {
    #     Type = "dbus";
    #     BusName = "org.freedesktop.secrets";
    #     ExecStart = "/run/wrappers/bin/gnome-keyring-daemon --foreground --start --components=secrets --login";
    #   };
    # };

  };

}
