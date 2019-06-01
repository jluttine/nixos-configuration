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

    # String used only when a remote SSH location for the backup
    remoteString = optionalString (cfg.host != null);

    # Support both local and SSH remote locations
    ssh = remoteString "${pkgs.openssh}/bin/ssh ${cfg.host}";

    # Whether to use compressing
    compress = remoteString "--no-compress";

    # "[user@]host:" for SSH remote locations, "" otherwise
    host = remoteString "${cfg.host}:";

    remoteUpdate = remoteString ''
      # Update the disk image in the remote alone to reduce network bandwidth
      LATEST_BACKUP=$(${ssh} ls -1 ${target}#* | tail -n 1)
      if [ "$LATEST_BACKUP" != "$OLDEST_BACKUP" ]; then
        echo "Syncing $LATEST_BACKUP to $OLDEST_BACKUP remotely.."
        ${ssh} diskrsync ${compress} "$LATEST_BACKUP" "$OLDEST_BACKUP"
      fi
    '';

    # Add double quotes around the target filename so it works more robustly
    target = "\"${cfg.filename}\"";

    backupScript = ''
      # Propagate errors through pipes correctly and raise errors on unknown
      # variables
      set -uo pipefail

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
      UPDATED_BACKUP=${target}#$(date +%Y%m%d%H%M%S)

      # Get the oldest version file to write into
      OLDEST_BACKUP=$(${ssh} ls -1 ${target}#* | head -n 1)

      ${remoteUpdate}

      echo "Start syncing to file ${host}$OLDEST_BACKUP .."

      # Update backup disk image
      ${pkgs.diskrsync}/bin/diskrsync ${compress} /dev/${cfg.volumeGroupName}/${cfg.snapshotName} ${host}"$OLDEST_BACKUP"

      echo "Syncing finished."

      # Rename the backup file with the correct timestamp
      ${ssh} mv "$OLDEST_BACKUP" "$UPDATED_BACKUP"

      echo "File renamed to ${host}$UPDATED_BACKUP"
    '';

    sshfsMount = remoteString ''
      # Mount read-only remote over SSH
      #LATEST_BACKUP=$(${ssh} ls -1 ${target}#* | tail -n 1)
      sshfs -o ro ${host}${baseDir} {cfg.sshfsDir}
    '';

    sshfsUmount = remoteString ''
      # Unmount SSH filesystem
      fusermount -u ${cfg.sshfsDir}
    '';

    mountScript = pkgs.writeScript "mount-diskrsync-backup" ''
      # Exit if any command fails
      set -e

      # Print commands
      set -x

      ${sshfsMount}

      # Use loop device to access the file as a file system
      LATEST_BACKUP=$(ls -1 ${cfg.sshfsDir}/${filenameWithoutPath}#* | tail -n 1)
      LOOPDEVICE=`losetup --read-only --show --find $LATEST_BACKUP`

      # Decrypt the encrypted file system
      cryptsetup luksOpen --readonly $LOOPDEVICE ${cfg.luksMapper}

      # Mount the decrypted file system. Need to use norecovery in order to
      # mount read-only.
      mount -o ro,norecovery /dev/mapper/${cfg.luksMapper} ${cfg.mountDir}
    '';

    umountScript = pkgs.writeScript "umount-diskrsync-backup" ''
      # Print commands
      set -x

      # Unmount decrypted file system
      umount ${cfg.mountDir}

      # Detach decryption
      cryptsetup luksClose /dev/mapper/${cfg.luksMapper}

      # Detach loop device(s)
      LOOPDEVICES=`losetup -j ${cfg.sshfsDir}/${WHATHERE} | sed 's/\(\/dev\/loop[[:digit:]]\).*/\1/'`
      for LOOPDEVICE in $LOOPDEVICES; do
        losetup -d $LOOPDEVICE
      done

      ${sshfsUmount}
    '';

  in mkIf cfg.enable {

    systemd.services.diskrsync = {
      description = "Disk image backup service using diskrsync";
      startAt = cfg.startAt;
      script = backupScript;
    };

  };

}
