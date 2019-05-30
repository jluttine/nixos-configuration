{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;

  xset = "${pkgs.xlibs.xset}/bin/xset";

  lockers = {

    # FIXME: If screen locking fails, suspend will still continue. Is it
    # possible to prevent suspend if locking fails? Probably not, if locking
    # just reacts to suspend that's happening? This can be reproduced, for
    # instance, by using removing --release from (s)uspend option in system
    # mode. Then, slock cannot grab keyboard and it fails but suspend still
    # happens. Adding `set -e` to the script didn't help.

    physlock = let
      physlock = "/run/wrappers/bin/physlock";
    in pkgs.writeScript "locker" ''
      #!/bin/sh
      if [ -z $XSS_SLEEP_LOCK_FD ]
      then
        ${physlock}
      else
        ${physlock} -d {XSS_SLEEP_LOCK_FD}<&-
        exec {XSS_SLEEP_LOCK_FD}<&-
      fi
    '';

    slock = let
      slock = "/run/wrappers/bin/slock";
    in pkgs.writeScript "locker" ''
      #!/bin/sh
      if [ -z $XSS_SLEEP_LOCK_FD ]
      then
        ${slock}
      else
        exec ${slock} {XSS_SLEEP_LOCK_FD}<&-
      fi
    '';

  };

  locker = lockers."${cfg.locker}";

  #
  # A good locker would perhaps lock each VT separately. So, if you lock the
  # screen, all VTs get locked separately, so you must provide a password to
  # access them. This way, each VT can be locked as physlock does and it doesn't
  # matter if you suspend while in VT without logged in user.
  #

in {

  options = with lib; {

    services.xserver.desktopManager.vaakko = {
      locker = mkOption {
        type = types.enum [ "physlock" "slock" ];
        default = "slock";
        #default = "physlock";
        description = ''
          Pre-configured screen locker

          Short summary of the choices:


          Physlock

          Pros:

          - Locks also virtual terminals so you cannot switch to another VT
            when locked.

          Cons:

          - If you suspend (lock) the laptop while in a VT without logged in
            user, the locking fails and nothing is locked when waking up.
            Perhaps do something like "until physlock" to force trying to lock
            until succeeds.

          - Doesn't support screen saving features via DPMS. See
            https://github.com/muennich/physlock/issues/9. One should use
            setterm but I couldn't figure out how and where to call it
            programmatically.


          Slock

          Pros:

          - Locks X no matter which VT you suspend in.

          Cons:

          - Locks only X so you can switch to other VTs even if they have logged
            in users. Slock does recommend disabling VT switching for the entire
            X but that isn't convenient because VTs are useful.

        '';
      };
    };

  };

  config = lib.mkIf cfg.enable {

    # nixpkgs.overlays = [
    #   self: super: {
    #     slock = super.slock.overrideAttrs (old: {
    #       patches = [
    #         (pkgs.fetchpatch {
    #           url = "https://tools.suckless.org/slock/patches/pam_auth/slock-pam_auth-20190207-35633d4.diff";
    #           sha256 = "0544fpd80hmpbkkbxl1pk487mdapaij5599b91jl90170ikhnp9v";
    #         })
    #       ];
    #       buildInputs = old.buildInputs ++ [ pkgs.pam ];
    #     });
    #   }
    # ];

    # From slock man pages:
    #
    # """
    # To make sure a locked screen can not be bypassed by switching VTs or
    # killing the X server with Ctrl+Alt+Backspace, it is recommended to disable
    # both in xorg.conf(5) for maximum security:
    #
    # Section "ServerFlags"
    #         Option "DontVTSwitch" "True"
    #         Option "DontZap"      "True"
    # EndSection
    # """
    #
    # This disables zapping. But we do want to allow switching to virtual
    # terminals. So maybe consider physlock or make sure you don't leave logged
    # in virtual terminals open when locking the screen.
    services.xserver.enableCtrlAltBackspace = false;

    services.physlock = {
      enable = cfg.locker == "physlock";
      allowAnyUser = true;
      # We use xss-lock to handle suspend&hibernate in addition to idle time.
      lockOn = {
        suspend = false;
        hibernate = false;
      };
    };

    programs = {
      slock.enable = cfg.locker == "slock";
      xss-lock = {
        enable = true;
        # TODO: Add dimming. See xss-lock man page for help.
        lockerCommand = "--transfer-sleep-lock -- ${locker}";
      };
    };

    systemd.user.services.xss-lock.preStart = ''
      ${xset} s on
      ${xset} s blank
      ${xset} s noexpose
      ${xset} s 300 10
      ${xset} dpms 300 600 1800
    '';

    # TODO: Perhaps use dmenu or something similar for this? i3 modes don't
    # capture all key presses.
    services.xserver.desktopManager.vaakko.i3Config = ''
      # Lock screen
      bindsym --release Ctrl+Mod1+l exec ${xset} s activate

      # Menu for log out, shut down, suspend etc
      bindsym Ctrl+Mod1+Delete mode "$mode_system"
      set $mode_system (l)ock, (e)xit, switch_(u)ser, (s)uspend, (h)ibernate, (r)eboot, (Shift+s)hutdown
      mode "$mode_system" {
          bindsym --release l exec --no-startup-id ${xset} s activate,        mode "default"
          bindsym --release e exec --no-startup-id i3-msg exit,               mode "default"
          bindsym --release u exec --no-startup-id dm-tool switch-to-greeter, mode "default"
          bindsym --release s exec --no-startup-id systemctl suspend,         mode "default"
          bindsym --release h exec --no-startup-id systemctl hibernate,       mode "default"
          bindsym --release r exec --no-startup-id systemctl reboot,          mode "default"
          bindsym --release Shift+s exec --no-startup-id systemctl poweroff,  mode "default"

          # Exit system mode: "Enter" or "Escape"
          bindsym Return mode "default"
          bindsym Escape mode "default"
      }
    '';

  };

}
