{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;

  xset = "${pkgs.xlibs.xset}/bin/xset";

  # For security reasons, all commands should use absolute path here. Otherwise,
  # a user can define arbitrary aliases for the commands and thus run whatever
  # as root.
  # physlock-start = pkgs.writeScriptBin "physlock-start" ''
  #   #!/bin/sh
  #   set -e
  #   USER=`${pkgs.coreutils}/bin/whoami`
  #   echo $USER
  #   systemctl start physlock
  # '';

  lockers = {

    # FIXME: If screen locking fails, suspend will still continue. Is it
    # possible to prevent suspend if locking fails? Probably not, if locking
    # just reacts to suspend that's happening? This can be reproduced, for
    # instance, by using removing --release from (s)uspend option in system
    # mode. Then, slock cannot grab keyboard and it fails but suspend still
    # happens. Adding `set -e` to the script didn't help.

    # physlock = let
    #   physlock = "/run/wrappers/bin/physlock";
    # in pkgs.writeScript "locker" ''
    #   #!/bin/sh
    #   set -e
    #   USER=`${pkgs.coreutils}/bin/whoami`
    #   if [ -z $XSS_SLEEP_LOCK_FD ]
    #   then
    #     ${physlock} -p "Username: $USER"
    #   else
    #     ${physlock} -p "Username: $USER" -d {XSS_SLEEP_LOCK_FD}<&-
    #     exec {XSS_SLEEP_LOCK_FD}<&-
    #   fi
    # '';

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

    services.xserver.desktopManager.nide = {
      locker = mkOption {
        type = types.enum [ "physlock" "slock" ];
        #default = "slock";
        default = "physlock";
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
            programmatically. SOLVED: Using kernel parameter consoleblank.


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
        suspend = true;
        hibernate = true;
      };
    };
    # environment.systemPackages = [
    #   physlock-start
    # ];
    # security.wrappers.physlock-start = {
    #   source = "${physlock-start}/bin/physlock-start";
    #   user = "root";
    # };
    security.sudo.extraRules = lib.mkAfter [
      {
        #users = [ "ALL" ];
        groups = [ "users" ];
        #runAs = "root";
        commands = [
          {
            command = "${pkgs.systemd}/bin/systemctl start physlock";
            options = [ "SETENV" "NOPASSWD" ];
          }
        ];
      }
    ];

    nixpkgs.overlays = lib.singleton (
      self: super: {
        physlock = super.physlock.overrideAttrs (oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "muennich";
            repo = "physlock";
            rev = "e4df70ccfc77b953f495c161bf6d07472e9d3434"; # PR 79
            sha256 = "0n9i9imrbjjkx2cbj7d341rygw4fgj5yzrq053kkg868nbm1axfm";
          };
          # postPatch = ''
          #   substituteInPlace main.c --replace '"sh"' '"/bin/sh"'
          # '';
          # patches = lib.singleton (
          #   pkgs.fetchpatch {
          #     url = "https://github.com/muennich/physlock/pull/79.patch";
          #     sha256 = "07f41yw3a8vynmrvmv2km8gf0q6xqcq09l8g250ljxvaz8lqxx0z";
          #   }
          # );
        });
        xidlehook = super.xidlehook.overrideAttrs (oldAttrs: {
          postPatch = ''
            substituteInPlace src/main.rs --replace '"sh"' '"/bin/sh"'
          '';
        });
      }
    );

    programs = {
      #slock.enable = cfg.locker == "slock";
      slock.enable = true;
      xss-lock = {
        enable = false;
        # TODO: Add dimming. See xss-lock man page for help.
        #extraOptions = [ "--transfer-sleep-lock" ];
        #lockerCommand = "${locker}";
        lockerCommand = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start physlock";
        extraOptions = [ "--notifier=${pkgs.xsecurelock}/libexec/xsecurelock/dimmer" ];
      };
    };

    systemd.user.services.xss-lock.preStart = ''
      ${xset} s on
      ${xset} s noblank
      ${xset} s noexpose
      ${xset} s 10 1
      ${xset} dpms 300 600 1800
    '';

    systemd.user.services.dim = {
      description = "Screen Dimming Daemon";
      environment = {
        XSECURELOCK_DIM_COLOR = "#000000";
        XSECURELOCK_DIM_TIME_MS = "5000";
        XSECURELOCK_DIM_ALPHA = "1";
      };
      serviceConfig.ExecStart = "${pkgs.xsecurelock}/libexec/xsecurelock/dimmer";
    };
    # systemd.user.services.xidlehook = {
    #   description = "Screen Lock Daemon";
    #   wantedBy = [ "nide.target" ];
    #   partOf = [ "nide.target" ];
    #   # serviceConfig.ExecStart = lib.strings.concatStringsSep " " [
    #   #   "${pkgs.xidlehook}/bin/xidlehook"
    #   #   "--not-when-fullscreen"
    #   #   "--not-when-audio"
    #   #   "--timer normal 5 '${pkgs.xsecurelock}/libexec/xsecurelock/dimmer' ' '"
    #   #   "--timer primary 15 '/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start physlock' ' '"
    #   # ];
    #       #--timer normal 5 '${pkgs.xsecurelock}/libexec/xsecurelock/dimmer' ' ' \
    #   script = ''
    #     ${pkgs.xidlehook}/bin/xidlehook --timer primary 5 '${pkgs.coreutils}/bin/echo "MOI"' '${pkgs.coreutils}/bin/echo "HEI"'
    #   '';
    #       # --not-when-fullscreen \
    #       # --not-when-audio \
    #       #--timer primary 5 '/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start physlock' ' '
    #       # Dimmer:
    #       #--timer normal 5 '${pkgs.systemd}/bin/systemctl --user start dim' '${pkgs.systemd}/bin/systemctl --user stop dim' \
    # };

    # I haven't been able to find any screensaver that doesn't lock the screen
    # while wathing videos. I tried at least xss-lock and xscreensaver.
    # xidlehook has support for detecting fullscreen and/or audio, so perhaps
    # use that to hook with some screensaver/locker. xautolock has features like
    # locknow and unlock which can be useful if I were to construct something
    # complext with xidlehook and physlock. For instance, use some simple X
    # locker but always when physlock unlocks, also unlock X (if permissions).
    #
    # gnome3.gnome-screensaver was somehow just broken. Perhaps it would need
    # some gnome stuff to work properly.

    # IDEA: To avoid Xorg screenlocker to start physlock when the user is in
    # virtual TTY, make it so that the first timer is just some blank screen,
    # and the second timer starts physlock when cancelled! This way, it only
    # gets started when there's activity in the virtual TTY. Or use a separate X
    # locker! And unlock that also when physlock unlocks.
    #
    # TODO: Add unlock hook to physlock. Actually, there's a PR #79 already! It
    # add -a flag which runs the given command after successfull authentication.
    #
    # How to use loginctl? Would it be useful somehow? It has lock-session etc.

    # Lock screen with Ctrl+Alt+L. This works also in TTYs!
    services.actkbd = {
      enable = true;
      bindings = lib.singleton {
        keys = [ 29 38 56 ];
        events = [ "key" ];
        command = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl start physlock";
        #command = "/run/wrappers/bin/physlock -d";
      };
    };

    environment.systemPackages = with pkgs; [
      i3lock
      xsecurelock
      xlockmore
      xidlehook
    ];

    # Monitor power saving in TTYs (not X). This didn't work.. It runs the
    # command also in shells in X (at least when sudo su). Also, it requires
    # someone to log in.
    #
    # environment.extraInit = ''
    #   ${pkgs.utillinux}/bin/setterm --blank 1 --powerdown 2
    # '';
    #
    # Let's try kernel parameters. Yey, this works! It doesn't operate on X, but
    # it works on TTYs and most importantly, with physlock!
    boot.kernelParams = [ "consoleblank=45" ];

    # Some thoughts about screen lockers:
    #
    # - Should provide possibility to disable VTY switching.
    #
    # - Should provide possibility to disable SysRq tricks.
    #
    # - Should support command that is run after locking complete (in foreground
    #   mode) or alternatively a command that is run after the screen locker has
    #   been unlocked (in daemon mode). Or both.

    # TODO: Perhaps use dmenu or something similar for this? i3 modes don't
    # capture all key presses.
    services.xserver.desktopManager.nide.i3Config = ''
      # Lock screen
      # bindsym --release Ctrl+Mod1+l exec ${xset} s activate

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
