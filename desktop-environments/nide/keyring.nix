{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;

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
    security.pam.services = {

      gdm.enableGnomeKeyring = true;
      kdm.enableGnomeKeyring = true;
      lightdm.enableGnomeKeyring = true;
      sddm.enableGnomeKeyring = true;
      slim.enableGnomeKeyring = true;

      # gdm.enableKwallet = true;
      # kdm.enableKwallet = true;
      # lightdm.enableKwallet = true;
      # sddm.enableKwallet = true;
      # slim.enableKwallet = true;

    };

    services.gnome3.gnome-keyring.enable = true;

    # If you want to auto-unlock kwallet, you need to run the following command
    # at DE startup. Installing kwallet-pam and having a tool to run autostart
    # desktop files should do the trick. Alternatively, run the following
    # command as part of the startup or as a one-shot systemd service.
    #
    # ${pkgs.kwallet-pam}/libexec/pam_kwallet_init

    # This doesn't seem to have any effect.. So let's just comment out..
    #
    services.dbus = {
      enable = true;
      packages = with pkgs; [
        gnome3.gnome-keyring
      ];
    };

    # The default SSH Agent (ssh-agent) doesn't store passphrases so let's use
    # the SSH Agent provided by GNOME Keyring. As far as I know, KDE Wallet has
    # no SSH Agent.
    programs.ssh.startAgent = false;
    environment.variables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
    systemd.user.services.gnome-keyring-ssh-agent = {
      description = "GNOME Keyring SSH Agent daemon";
      wantedBy = [ "nide.target" ];
      partOf = [ "nide.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.gnome3.gnome-keyring}/bin/gnome-keyring-daemon --foreground --start --components=ssh";
      };
    };

    # GNOME Keyring D-BUS activation is somehow broken. Or maybe D-BUS
    # activation in NixOS is in general somehow broken because also KBDD D-BUS
    # activation is broken. Whenever org.freedesktop.secrets D-BUS is needed,
    # the first attempt fails but the corresponding process starts. Then, the
    # next D-BUS attempt works. This service is a workaround: we poke the D-BUS
    # before any other process so it gets activated and then other processes can
    # use it successfully. This service just pokes some endpoint, doesn't really
    # matter what.
    #
    # TODO: Add D-BUS activation support to GNOME Keyring.
    systemd.user.services.gnome-keyring-secrets-init = {
      description = "org.freedesktop.secrets initialization";
      wantedBy = [ "nide.target" ];
      partOf = [ "nide.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        ExecStart = let
          dbus-send = "${pkgs.dbus}/bin/dbus-send";
        in "${dbus-send} --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.StartServiceByName string:org.freedesktop.secrets uint32:0";
      };
    };

    # NOTE: ssh-askpass of GNOME Keyring (part of Seahorse) doesn't store
    # username&password for git. Thus, let's use Kwallet connected ssh-askpass.
    # Oh, actually, using git-credential-libsecret fixes this for GNOME Keyring.
    # So, let's use GNOME Keyring for SSH_ASKPASS after all! Now, we don't need
    # Kwallet for anything so it can be removed.
    programs.ssh.askPassword = "${pkgs.gnome3.seahorse}/libexec/seahorse/ssh-askpass";
    #programs.ssh.askPassword = "${pkgs.ksshaskpass}/bin/ksshaskpass";

    # Fixes "org.a11y.Bus was not provided by any .service files" error
    services.gnome3.at-spi2-core.enable = true;
    #environment.variables.NO_AT_BRIDGE = "1";

    environment.systemPackages = with pkgs; [

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
