{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;


in {

  options = with lib; {

    services.xserver.desktopManager.vaakko = {};

  };

  config = lib.mkIf cfg.enable {

    services.xserver.desktopManager.vaakko.i3Config = ''
      # Move focus
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right

      # Move focused window
      bindsym $mod+Shift+h move left
      bindsym $mod+Shift+j move down
      bindsym $mod+Shift+k move up
      bindsym $mod+Shift+l move right

      # Resize focused window
      bindsym $mod+Ctrl+h resize shrink width 10 px or 10 ppt
      bindsym $mod+Ctrl+j resize grow height 10 px or 10 ppt
      bindsym $mod+Ctrl+k resize shrink height 10 px or 10 ppt
      bindsym $mod+Ctrl+l resize grow width 10 px or 10 ppt

      # Focus the parent/child container
      bindsym $mod+a focus parent
      bindsym $mod+d focus child

      # Change container layout (stacked, tabbed, toggle split)
      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+e layout toggle split

      # Split in horizontal/vertical orientation
      bindsym $mod+bar   split h
      bindsym $mod+minus split v

      # Enter fullscreen mode for the focused container
      bindsym $mod+f fullscreen toggle

      # Focus/toggle tiling/floating
      bindsym $mod+Tab       focus mode_toggle
      bindsym $mod+Shift+Tab floating toggle
    '';

  };

}
