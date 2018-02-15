{ config, lib, pkgs, ...}:

with lib;

let

  cfg = config.services.salmon;

  extraLibs = cfg.extraLibs cfg.pythonPackages;
  salmon = cfg.package cfg.pythonPackages;

  penv = cfg.pythonPackages.python.buildEnv.override {
    extraLibs = extraLibs ++ [salmon];
  };

  uid = toString config.users.users."${cfg.user}".uid;
  gid = toString config.users.groups."${cfg.group}".gid;
  # pid = "${cfg.directory}/run/stmp.pid";

in {

  options.services.salmon = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable Salmon, a Python mail server";
    };

    pythonPackages = mkOption {
      # TODO: Is there a type for this?
      default = pkgs.pythonPackages;
      defaultText = "pkgs.pythonPackages";
      description = "Python package set to use";
    };

    package = mkOption {
      # TODO: Is there a type for this?
      default = ps: ps.salmon-mail;
      defaultText = "ps: ps.salmon-mail";
      description = "TODO";
    };

    extraLibs = mkOption {
      # TODO: Is there a type for this?
      default = ps: [];
      defaultText = "ps: []";
      description = "TODO";
    };

    directory = mkOption {
      type = types.path;
      default = "/var/lib/salmon";
      description = "Directory for storing the state";
    };

    user = mkOption {
      type = types.str;
      # FIXME
      default = "salmon";
      description = "TODO";
    };

    group = mkOption {
      type = types.str;
      # FIXME
      default = "salmon";
      description = "TODO";
    };

    bootModule = mkOption {
      type = types.str;
      description = "TODO";
    };

    settingsModule = mkOption {
      type = types.str;
      description = "TODO";
    };

  };

  config = mkIf cfg.enable {

    users.extraUsers = mkIf (cfg.user == "salmon") {
      salmon = {
        group = cfg.group;
        uid = 661; # config.ids.uids.salmon;
        description = "Salmon daemon user";
      };
    };

    users.extraGroups = mkIf (cfg.group == "salmon") {
      salmon.gid = 661; # config.ids.gids.salmon;
    };

    systemd.services.salmon = {
      description = "Salmon Mail Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        SALMON_SETTINGS_MODULE = "${cfg.settingsModule}";
      };
      serviceConfig = {
        WorkingDirectory = cfg.directory;
        ExecStart = "${penv}/bin/salmon start --uid ${uid} --gid ${gid} --boot ${cfg.bootModule}";
        ExecStop = "${penv}/bin/salmon stop";
      };
      # Make state directories
      preStart = ''
        mkdir -p ${cfg.directory}/run
        mkdir -p ${cfg.directory}/logs
        chown -R ${cfg.user}:${cfg.group} ${cfg.directory}
        chmod -R o-rwx ${cfg.directory}
      '';
    };

  };

}
