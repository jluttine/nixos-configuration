{ lib, config, pkgs, ... }:

with lib;
{

  options.localConfiguration.extraServices.backup = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
      '';
    };
    compress = mkOption {
      type = types.bool;
      default = true;
      description = ''
      '';
    };
    snapshotName = mkOption {
      type = types.str;
      description = ''
      '';
    };
    volumeGroupName = mkOption {
      type = types.str;
      description = ''
      '';
    };
    logicalVolumeName = mkOption {
      type = types.str;
      description = ''
      '';
    };
    snapshotSize = mkOption {
      type = types.str;
      default = "-l100%FREE";
      description = ''
      '';
    };
    host = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "johndoe@domain.com";
      description = ''
        Null for local or [user@]host for SSH remote location.
      '';
    };
    filename = mkOption {
      type = types.str;
      example = "/home/johnsmith/backups/mylaptop.img";
      description = ''
        Base filename for the backup files.
      '';
    };
    startAt = mkOption {
      type = types.str;
      example = "Sun 14:00:00";
      description = ''
        Automatically start this unit at the given date/time, which
        must be in the format described in
        <citerefentry><refentrytitle>systemd.time</refentrytitle>
        <manvolnum>7</manvolnum></citerefentry>.  This is equivalent
        to adding a corresponding timer unit with
        <option>OnCalendar</option> set to the value given here.
      '';
    };
  };

  config = let

    cfg = config.localConfiguration.extraServices.backup;

    # Support both local and SSH remote locations
    ssh = if cfg.host == null then "" else "${pkgs.openssh}/bin/ssh ${cfg.host}";

    # Whether to use compressing
    compress = optionalString (!cfg.compress) "--no-compress";

    # "[user@]host:" for SSH remote locations, "" otherwise
    host = if cfg.host == null then "" else "${cfg.host}:";

    # Add double quotes around the target filename so it works more robustly
    target = "\"${cfg.filename}\"";

    #backupScript = pkgs.writeScript "diskrsync-backup.sh" ''
    backupScript = ''
      # Delete existing snapshot (if one exists)
      set +e
      ${pkgs.lvm2}/bin/lvremove --yes ${cfg.volumeGroupName}/${cfg.snapshotName}
      RETVAL=$?
      if [ $RETVAL -ne 0 ] && [ $RETVAL -ne 5 ]; then
        exit $RETVAL
      fi
      set -e

      # Take new snapshot
      ${pkgs.lvm2}/bin/lvcreate ${cfg.snapshotSize} -s -n ${cfg.snapshotName} ${cfg.volumeGroupName}/${cfg.logicalVolumeName}

      # Timestamp of the snapshot is used as backup file suffix
      FINISHED_DST=${target}$(date +%Y%m%d%H%M%S)

      # Get the oldest version file to write into
      UNFINISHED_DST=$(${ssh} ls -1 ${target}#* | head -n 1)

      echo "Start syncing to file ${host}$UNFINISHED_DST .."

      # Update backup disk image
      ${pkgs.diskrsync}/bin/diskrsync ${compress} /dev/${cfg.volumeGroupName}/${cfg.snapshotName} ${host}${target}

      echo "Syncing finished."

      # Rename the backup file with the correct timestamp
      ${ssh} mv $UNFINISHED_DST $FINISHED_DST

      echo "File renamed to ${host}$FINISHED_DST"
    '';

  in mkIf cfg.enable {

    systemd.services.diskrsync = {
      description = "Disk image backup service using diskrsync";
      startAt = cfg.startAt;
      script = backupScript;
    };

  };

}
