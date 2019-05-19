{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.vaakko;


in {

  options = with lib; {

    services.xserver.desktopManager.vaakko = {};

  };

  config = lib.mkIf cfg.enable {

    # There also is the (new) i3-dmenu-desktop which only displays applications
    # shipping a .desktop file. It is a wrapper around dmenu, so you need that
    # installed.
    services.xserver.desktopManager.vaakko.i3Config = ''
      bindsym $mod+Return exec st
      bindsym $mod+Home exec dolphin
    '';

    # You can add .desktop files according to XDG Autostart specs. However, for
    # that to work in i3, you may need to install dex (or something similar).

    # Other core apps for making a complete desktop environment experience.
    environment.systemPackages = with pkgs; [
      # Simple tabless terminal
      st

      # Simple tabless web browser options
      vimb
      surf
      qutebrowser
      luakit

      # Simple file manager
      dolphin
      #thunar

      # Monitor layout configuration
      arandr

    ];

    # Some notes on browser options:
    #
    # Vimb
    # + vim key bindings
    # + profiles (launch-time choice)
    # + private browsing (to some extent?)
    # (+ no tabs)
    # - view certificate?
    # - smooth scrolling buggy?
    #
    # Luakit
    # + vim key bindings
    # (+/- has tabs but can open in new window with w)
    # - no profiles?
    # - no private browsing (with plugins perhaps)
    # - view certificate?
    #
    # Qutebrowser
    # + okay-ish key bindings
    # + profiles (launch-time choice)
    # - opening new windows not well supported
    # - quite massive..
    #
    # Surf
    # - no profiles
    # - no private browsing
    # - not very good key bindings
    #
    # Many common browsers:
    # - very bad keyboard interface
    # - tabs and address bar take a lot of vertical space

    # Apply some modifications to the apps.
    nixpkgs.overlays = [
      (
        self: super: {
          st = super.st.override {
            patches = [
	      # Maybe the theme should be controlled by the shell? Or maybe the
	      # shell cannot control the background color of the terminal?
	      # Hmm.. These solarized themes didn't work well with Spacemacs..
	      # Not sure how to fix that. Is the problem in these themes or
	      # spacemacs or is everything working as it "should"..
              # (pkgs.fetchpatch {
              #   url = "https://st.suckless.org/patches/solarized/st-no_bold_colors-20170623-b331da5.diff";
              #   sha256 = "0ff48vrm6kx1zjrhl2mmwv85325xi887lqh26410ygg85dxrd0c8";
              # })
              # This patch adds dark and light color themes. You can switch
              # between them with F6.
              # (pkgs.fetchpatch {
              #   url = "https://st.suckless.org/patches/solarized/st-solarized-both-20190128-3be4cf1.diff";
              #   sha256 = "16nyrgc5n0yl4y3m39wkgc1gal20khf9dcnidfy28lax49kmshn4";
              # })
            ];
          };
        }
      )
    ];

  };

}
