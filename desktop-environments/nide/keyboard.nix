{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;

  kbdd-daemon = pkgs.writeTextFile {
    name = "kbdd-daemon";
    destination = "/share/dbus-1/services/ru.gentoo.KbddService.service";
    text = ''
      [D-BUS Service]
      Name=ru.gentoo.KbddService
      Exec=${pkgs.kbdd}/bin/kbdd --nodaemon
      SystemdService=kbdd.service
    '';
  };

in {

  options = {};

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [

      # Just adding this to installed packages enables the D-Bus service.
      kbdd-daemon

    ];

    # Without this, D-Bus didn't seem to work.. Not sure though.
    services.xserver.startDbusSession = true;
    services.xserver.updateDbusEnvironment = true;

    # KBDD doesn't support D-BUS activation. Thus, when trying to switch
    # keyboard layout the first time in a session, it just launches kbdd but
    # doesn't do anything. Then, one must send the layout switching command
    # again in order to actually switch the layout. This is a workaround for
    # that issue. When the desktop environment is started, this just sends some
    # dummy call to KBDD daemon which actually causes it to activate itself.
    #
    # TODO: Add D-BUS activation support to KBDD.
    systemd.user.services.kbdd-init = {
      description = "KBDD initialization";
      wantedBy = [ "nide.target" ];
      partOf = [ "nide.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        ExecStart = let
          dbus-send = "${pkgs.dbus}/bin/dbus-send";
        in "${dbus-send} --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.getCurrentLayout";
      };
    };

    # KBDD doesn't work if it is started without a window in focus. It'll not
    # detect EWMH support and fallback to some generic mode that doesn't
    # remember the layout of the windows.. This patch just forces it to believe
    # there is always EWMH support whether it can detect it or not. A better
    # solution could be that KBDD would have a global state keyboard layout
    # which is used when no window is focused.
    #
    # TODO: Add global (no window in focus) keyboard layout state.
    nixpkgs.overlays = [(self: super: {
      kbdd = super.kbdd.overrideAttrs (oldAttrs: {
        patches = [
          ./kbdd.patch
          # (pkgs.fetchpatch {
          #   url = "https://st.suckless.org/patches/solarized/st-no_bold_colors-20170623-b331da5.diff";
          #   sha256 = "0ff48vrm6kx1zjrhl2mmwv85325xi887lqh26410ygg85dxrd0c8";
          # })
        ];
      });
    })];

    # Keybinding for switching the keyboard layout
    services.xserver.desktopManager.nide.i3Config = let
      dbus-send = "${pkgs.dbus}/bin/dbus-send";
    in ''
      bindsym $mod+Shift+space exec ${dbus-send} --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.prev_layout
    '';

    # FIXME: These should be defined by the user, not the desktop environment.
    services.xserver.layout = "fi,us";
    services.xserver.xkbOptions = "caps:escape";

    #
    # TODO: For systray companion, see: https://hub.darcs.net/zabbal/ktc
    #

  };

}
