{ config, pkgs, lib, ... }:

let

  cfg = config.services.xserver.desktopManager.nide;

  # Put the configuration file in /run/current-system/sw/etc/xdg/polybar/config
  # so we can fix that path and the file can be updated with nixos-rebuild but
  # it suffices to just reload polybar without needing to restart it. We could
  # just use nix path and not install the config in system packages, but then we
  # would need to restart polybar whenever we modify the configuration.
  configPath = "/etc/xdg/polybar/config";
  polybarConfigFile = pkgs.writeTextFile {
    name = "polybar-config";
    text = lib.generators.toINI {} cfg.polybar.config;
    destination = configPath;
  };

  polybar-kdeconnect = let
    deps = lib.makeBinPath [ pkgs.qt5.qttools pkgs.coreutils pkgs.gawk pkgs.rofi ];
  in pkgs.stdenv.mkDerivation rec {
    pname = "polybar-kdeconnect";
    version = "unstable-2019-05-28";
    src = pkgs.fetchFromGitHub {
      owner = "HackeSta";
      repo = pname;
      rev = "f640a070654f4be0ea949ffd07c8bf1fcf1b6b50";
      sha256 = "0sidj654gys9fdp5v6cmr2s9lmxaps2dacq46wcy666ykgdjyx29";
    };
    buildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir -p $out/libexec
      mv polybar-kdeconnect.sh $out/libexec/
      wrapProgram $out/libexec/polybar-kdeconnect.sh --prefix PATH : ${deps};
    '';
    doCheck = false;
  };

  firacode-nerdfont = let
    pname = "FiraCode";
    version = "v2.0.0";
  in pkgs.stdenv.mkDerivation rec {
    name = "${pname}-nerdfont-${version}";

    src = pkgs.fetchzip {
      url       = "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${pname}.zip";
      sha256    = "1bnai3k3hg6sxbb1646ahd82dm2ngraclqhdygxhh7fqqnvc3hdy";
      stripRoot = false;
    };

    buildCommand = ''
      install --target $out/share/fonts/opentype -D $src/*.otf
    '';

    meta = with pkgs.stdenv.lib; {
      description = "Nerdfont version of Fira Code";
      homepage = https://github.com/ryanoasis/nerd-fonts;
      license = licenses.mit;
    };
  };

  iosevka-nerdfont = let
    pname = "Iosevka";
    version = "v2.0.0";
  in pkgs.stdenv.mkDerivation rec {
    name = "${pname}-nerdfont-${version}";

    src = pkgs.fetchzip {
      url       = "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${pname}.zip";
      sha256    = "1rnl13kqp7l6fb42lqsc45yjcscviq2qpgnbg2g3r0a7aks9b1yi";
      stripRoot = false;
    };

    buildCommand = ''
      install --target $out/share/fonts/opentype -D $src/*.otf
    '';

    meta = with pkgs.stdenv.lib; {
      description = "Nerdfont version of Iosevka";
      homepage = https://github.com/ryanoasis/nerd-fonts;
      license = licenses.mit;
    };
  };

in {

  options = with lib; {
    services.xserver.desktopManager.nide = {
      polybar.config = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {

          "settings" = {
            screenchange-reload = "true";
          };

          "colors" = {
            background = "#222";
            background-alt = "#444";
            foreground = "#dfdfdf";
            foreground-alt = "#555";
            primary = "#ffb52a";
            secondary = "#e60053";
            alert = "#bd2c40";
          };

          "bar/nide" = {
            width = "100%";
            height = "27";
            fixed-center = "true";
            background = "\${colors.background}";
            foreground= "\${colors.foreground}";
            line-size = "3";
            line-color = "#f00";
            border-size = "0";
            module-margin-left = "1";
            module-margin-right = "2";
            modules-left = "i3 title";
            modules-center = "date";
            modules-right = "xkeyboard pulseaudio battery kdeconnect";
            font-0 = "fixed:pixelsize=10;1";
            font-1 = "unifont:fontformat=truetype:size=8:antialias=false;0";
            #font-2 = "Wuncon Siji:pixelsize=10;1";
            font-2 = "Siji:pixelsize=10;0";
            font-3 = "FuraCode Nerd Font:pixelsize=10;0";
            tray-position = "right";
            tray-padding = "2";
            cursor-click = "pointer";
            cursor-scroll = "ns-resize";
            enable-ipc = "true";
          };

          "module/title" = {
            type = "internal/xwindow";
            label = "%title%";
            label-maxlen = "50";
          };

          "module/date" = {
            type = "internal/date";
            cnterval = "5";
            date = "%a %b %e";
            time = "%H:%M";
            #format-prefix = "";
            format-prefix-foreground = "\${colors.foreground-alt}";
            label = "%date% %time%";
          };

          "module/i3" = {
            type = "internal/i3";
            format = "<label-state> <label-mode>";
            index-sort = "true";
            wrapping-scroll = "false";

            # Only show workspaces on the same output as the bar
            # "pin-workspaces" = "true";

            label-mode-padding = "2";
            label-mode-foreground = "#000";
            label-mode-background = "\${colors.primary}";

            # focused = Active workspace on focused monitor
            label-focused = "%index%";
            label-focused-background = "\${colors.background-alt}";
            # label-focused-underline= "\${colors.primary}";
            label-focused-padding = "2";

            # unfocused = Inactive workspace on any monitor
            label-unfocused = "%index%";
            label-unfocused-padding = "2";

            # visible = Active workspace on unfocused monitor
            label-visible = "%index%";
            label-visible-background = "\${self.label-focused-background}";
            # label-visible-underline = "\${self.label-focused-underline}";
            label-visible-padding = "\${self.label-focused-padding}";

            # urgent = Workspace with urgency hint set
            label-urgent = "%index%";
            label-urgent-background = "\${colors.alert}";
            label-urgent-padding = "2";

            # Separator in between workspaces
            # label-separator = "|";

          };

          "module/battery" = {
            type = "internal/battery";
            battery = "BAT0";
            adapter = "ADP1";
            full-at = "98";
            format-charging = "<animation-charging> <label-charging>";
            ramp-capacity-0 = "";
            ramp-capacity-1 = "";
            ramp-capacity-2 = "";
            ramp-capacity-foreground = "\${colors.foreground-alt}";
            animation-charging-0 = "";
            animation-charging-1 = "";
            animation-charging-2 = "";
            animation-charging-foreground = "\${colors.foreground-alt}";
            animation-charging-framerate = "750";
            animation-discharging-0 = "";
            animation-discharging-1 = "";
            animation-discharging-2 = "";
            animation-discharging-foreground = "\${colors.foreground-alt}";
            animation-discharging-framerate = "750";
          };

          "module/pulseaudio" = {
            type = "internal/pulseaudio";
            format-volume = "<label-volume> <bar-volume>";
            label-volume = "VOL %percentage%%";
            label-volume-foreground = "\${root.foreground}";
            label-muted = "🔇 muted";
            label-muted-foreground = "#666";
            bar-volume-width = "10";
            bar-volume-foreground-0 = "#55aa55";
            bar-volume-foreground-1 = "#55aa55";
            bar-volume-foreground-2 = "#55aa55";
            bar-volume-foreground-3 = "#55aa55";
            bar-volume-foreground-4 = "#55aa55";
            bar-volume-foreground-5 = "#f5a70a";
            bar-volume-foreground-6 = "#ff5555";
            bar-volume-gradient = "false";
            bar-volume-indicator = "|";
            bar-volume-indicator-font = "2";
            bar-volume-fill = "─";
            bar-volume-fill-font = "2";
            bar-volume-empty = "─";
            bar-volume-empty-font = "2";
            bar-volume-empty-foreground = "\${colors.foreground-alt}";
          };

          "module/xkeyboard" = {
            type = "internal/xkeyboard";
            blacklist-0 = "num lock";
            label-layout = "%layout%";
            label-indicator-padding = "2";
            label-indicator-margin = "1";
            label-indicator-background = "\${colors.secondary}";
          };

          "module/kdeconnect" = {
            type = "custom/script";
            exec = "${polybar-kdeconnect}/libexec/polybar-kdeconnect.sh -d";
            tail = "true";
          };

        };
      };
    };
  };

  config = lib.mkIf cfg.enable {

    # Perhaps, instead of downloading the huge nerdfonts package with all the
    # fonts, just package the ones that are needed. See an example here:
    # https://gist.github.com/worldofpeace/d546167739cb41d87f965c9a81e78530
    #
    # At least this font supports Unicode characters. See:
    # https://github.com/polybar/polybar/issues/392
    fonts.fonts = with pkgs; [
      siji
      iosevka
      #iosevka-nerdfont
      firacode-nerdfont
    ];

    #services.xserver.desktopManager.nide.polybar.config."bar/nide" = {};
    nixpkgs.overlays = [
      (
        self: super: {
          nerdfonts = super.nerdfonts.override {
            withFont = "Iosevka";
          };
        }
      )
      (
        self: super: {
          polybar = super.polybar.override {
            i3Support = true;
            #mpdSupport = true;
            pulseSupport = true;
            #githubSupport = true;
            nlSupport = false;
            iwSupport = true;
            wirelesstools = pkgs.wirelesstools;
          };
        }
      )
    ];

    systemd.user.services.polybar = {
      description = "Polybar daemon";
      wantedBy = [ "nide.target" ];
      partOf = [ "nide.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polybar}/bin/polybar --reload --config=/run/current-system/sw${configPath} nide";
      };
    };

    services.xserver.desktopManager.nide.i3Config = let
      polybar-msg = "${pkgs.polybar}/bin/polybar-msg";
    in ''
      bindsym $mod+Shift+BackSpace exec ${polybar-msg} cmd toggle
      bindsym $mod+BackSpace border toggle
    '';
      #bindsym $mod+BackSpace [class="^.*"] border toggle
    environment.systemPackages = with pkgs; [
      polybar
      polybarConfigFile
    ];

  };

}
