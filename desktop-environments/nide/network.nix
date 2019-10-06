{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;


  networkmanagerConfigFile = pkgs.writeTextFile {
    name = "config.ini";
    #text = lib.generators.toINI {} cfg.polybar.config;
    text = ''
    [dmenu]
    fn = -*-terminus-medium-*-*-*-16-*-*-*-*-*-*-*
    dmenu_command = /run/current-system/sw/bin/rofi
    # # Note that dmenu_command can contain arguments as well like `rofi -width 30`
    # # Rofi and dmenu are set to case insensitive by default `-i`
    # l = number of lines to display, defaults to number of total network options
    # fn = font string
    # nb = normal background (name, #RGB, or #RRGGBB)
    # nf = normal foreground
    # sb = selected background
    # sf = selected foreground
    # b =  (just set to empty value and menu will appear at the bottom
    # m = number of monitor to display on
    # p = Custom Prompt for the networks menu
    # pinentry = Pinentry command
    # rofi_highlight = <True or False> # (Default: False) use rofi highlighting instead of '**'

    # # override normal foreground and background colors (dmenu) or use the
    # # -password option (rofi) to obscure passphrase entry
    # [dmenu_passphrase]
    # nf = #222222
    # nb = #222222
    # rofi_obscure = True

    [editor]
    terminal = st
    gui_if_available = True
    # terminal = <name of terminal program>
    # gui_if_available = <True or False>
    '';
    destination = "/etc/xdg/networkmanager-dmenu";
  };

in {

  options = with lib; {};

  config = lib.mkIf cfg.enable {

    # Use Systemd resolver??
    #services.resolved.enable = true;

    # For some reason, wpa_supplicant backend fails to auto-connect to password
    # protected WLANs at login time. It doesn't find secrets that are stored in
    # GNOME Keyring. However, immediately after login, restarting the network
    # manager or manually choosing the WLAN, connects successfully. Anyway,
    # switching to iwd backend fixes the issue. See:
    # https://github.com/NixOS/nixpkgs/issues/69368
    networking.networkmanager.wifi.backend = "iwd";

    systemd.user.services.nm-applet = {
      description = "Network manager applet";
      wantedBy = [ "nide.target" ];
      partOf = [ "nide.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
        Restart = "always";
      };
    };

    # services.xserver.desktopManager.nide.i3Config = ''
    #   bindsym $mod+space exec ${pkgs.rofi}/bin/rofi -show drun -modi drun#run -matching fuzzy -show-icons
    # '';
    environment.systemPackages = with pkgs; [
      networkmanager_dmenu
      networkmanagerConfigFile
    ];

  };

}
