{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;

  kill-window = let
    xprop = "${pkgs.xlibs.xprop}/bin/xprop";
    awk = "${pkgs.gawk}/bin/awk";
  in pkgs.writeScript "kill-window" ''
    #!/bin/sh
    set -x
    window_ID=$(${xprop} -root | ${awk} '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
    window_PID=$(${xprop} -id $window_ID | ${awk} '/_NET_WM_PID\(CARDINAL\)/{print $NF}')
    kill -$1 $window_PID
  '';

in {

  options = {};

  config = lib.mkIf cfg.enable {

    services.xserver.desktopManager.nide.i3Config = let
    in ''
      bindsym $mod+Escape kill
      bindsym $mod+Shift+Escape exec --no-startup-id ${kill-window} TERM
      bindsym $mod+Shift+Ctrl+Escape exec --no-startup-id ${kill-window} KILL
    '';

  };

}
