{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;


in {

  options = with lib; {

    services.xserver.desktopManager.vaakko = {};

  };

  config = lib.mkIf cfg.enable {

    services.xserver.desktopManager.vaakko.i3Config = ''
      # Assign workspace names to variables
      set $ws1 "1"
      set $ws2 "2"
      set $ws3 "3"
      set $ws4 "4"
      set $ws5 "5"
      set $ws6 "6"
      set $ws7 "7"
      set $ws8 "8"
      set $ws9 "9"
      set $ws10 "10"

      # Switch to workspace
      bindsym $mod+1     workspace $ws1
      bindsym $mod+2     workspace $ws2
      bindsym $mod+3     workspace $ws3
      bindsym $mod+4     workspace $ws4
      bindsym $mod+5     workspace $ws5
      bindsym $mod+6     workspace $ws6
      bindsym $mod+7     workspace $ws7
      bindsym $mod+8     workspace $ws8
      bindsym $mod+9     workspace $ws9
      bindsym $mod+0     workspace $ws10
      bindsym $mod+Left  workspace prev
      bindsym $mod+Right workspace next

      # Move focused container to workspace
      bindsym $mod+Shift+1     move container to workspace $ws1;  workspace $ws1
      bindsym $mod+Shift+2     move container to workspace $ws2;  workspace $ws2
      bindsym $mod+Shift+3     move container to workspace $ws3;  workspace $ws3
      bindsym $mod+Shift+4     move container to workspace $ws4;  workspace $ws4
      bindsym $mod+Shift+5     move container to workspace $ws5;  workspace $ws5
      bindsym $mod+Shift+6     move container to workspace $ws6;  workspace $ws6
      bindsym $mod+Shift+7     move container to workspace $ws7;  workspace $ws7
      bindsym $mod+Shift+8     move container to workspace $ws8;  workspace $ws8
      bindsym $mod+Shift+9     move container to workspace $ws9;  workspace $ws9
      bindsym $mod+Shift+0     move container to workspace $ws10; workspace $ws10
      bindsym $mod+Shift+Left  move container to workspace prev;  workspace prev
      bindsym $mod+Shift+Right move container to workspace next;  workspace next
    '';

  };

}
