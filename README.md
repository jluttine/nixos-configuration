# NixOS configurations

My personal NixOS configurations.

You can put these configuration files under `/etc/nixos` as follows:

```
nix-shell -p yadm -p git -p gnupg1orig
yadm clone https://github.com/jluttine/nixos-configuration.git -w /etc/nixos -Y /etc/nixos/.yadm
yadm -Y /etc/nixos/.yadm decrypt
yadm -Y /etc/nixos/.yadm alt
exit
```

If your hostname isn't included in the configuration file alternatives, symlinks
aren't created properly. See Yadm manuals for more information.


## Installing NixOS

Boot to NixOS installer.


### Setting up internet connection

The installer needs internet connection. If you need to set up WLAN:
```
nmcli dev wifi connect <name> password <password>
```
Test internet connection:
```
ping google.com
```

### Creating fully encrypted file systems

You first need to decide how to partition your disk(s). I'm using fully
encrypted file systems with GPT partition table. I created the partitions with
fdisk. Run `fdisk /dev/some-device` for each device you want to partition. I
created GPT partition tables for them. Below are my somewhat cryptic and compact
notes on how I partitioned my two machines.

On a laptop with only one disk, I created an unencrypted partition for `/boot`
and an encrypted partition for `/`:

- 250 GB SSD
  - partition 4, type 4 = BIOS boot, size = 1M
  - partition 1, size = 1G, ext4 nixos-boot, `/boot`
  - partition 2, size = 100%, LUKS luks-nixos-root, ext4 nixos-root, `/`

On a server with three disks:

- 60 GB SSD
  - partition 4, type 4 = BIOS boot, size = 1M
  - partition 1, size = 1G, ext4 nixos-boot, `/boot`
  - partition 2, size = 100%, LUKS luks-nixos-root, ext4 nixos-root, `/`
- 2 TB HDD
  - partition 1, size = 100%, LUKS luks-nixos-media, ext4 nixos-media, `/media`
- 600 GB HDD
  - partition 1, type 31 = LVM, size = 500G, VG vg-nixos-var
    - LV lv-nixos-var, size = 450G, LUKS luks-nixos-var, ext4 nixos-var, `/var`
    - remaining 50G will be reserved for snapshots
  - partition 2, size = 100%, LUKS luks-nixos-home, ext4 nixos-home, `/home`

One notable goal of the above construction is to have everything that needs to
be backed up under `/var`. This encrypted partition is under LVM, so I can take
a snapshot of the encrypted disk and then sync that encrypted disk image with
diskrsync to an untrusted remote location efficiently and safely. Also, note
that I needed to create 1M BIOS boot partitions so that GPT works with BIOS.

Creating logical volumes:

```
# Use pvcreate for each partition you want to put under LVM
pvcreate /dev/put-device-here
# List all partitions this volume group should use
vgcreate put-vg-label-here /dev/put-devices-here
# Create logical volumes for the volume groups
lvcreate -L 666G -n put-lv-label-here put-vg-label-here
```

In my case, I put only one partition under LVM. I had only one volume group
which contained only one logical volume.

Creating LUKS encrypted file systems:

```
cryptsetup -y -v luksFormat /dev/put-device-here
cryptsetup open /dev/put-device-here put-luks-label-here
mkfs.ext4 -L put-filesystem-label-here /dev/mapper/put-luks-label-here
```

Mount each file system to its place under `/mnt`. For instance, I mounted
`nixos-root` under `/mnt` and `nixos-boot` under `/mnt/boot`.


#### Backing up encrypted logical volume

```
modprobe dm-snapshot    # if needed
lvcreate -l 100%FREE -s -n lv-nixos-var-snapshot /dev/vg-nixos-var/lv-nixos-var
diskrsync --no-compress /dev/vg-nixos-var/lv-nixos-var-snapshot user@host:/path/to/disk.img
```



### Fetching configuration

Create folder under which configuration will be fetched:
```
mkdir -p /mnt/etc
```

Set the hostname so yadm will use correct host specific configurations.

```
hostname <name>
```

Get the configuration from GitHub using yadm:

```
nix-shell -p yadm -p git -p gnupg1orig
yadm clone https://github.com/jluttine/nixos-configuration.git -w /mnt/etc/nixos -Y /mnt/etc/nixos/.yadm
yadm -Y /mnt/etc/nixos/.yadm decrypt
yadm -Y /mnt/etc/nixos/.yadm alt
exit
```

This funny thing is done because `nixos-install` changes root and yadm has
created symlinks with /mnt at the beginning:

```
ln -s . /mnt/mnt
```

Generate hardware configuration automatically:

```
nixos-generate-config --root /mnt
```

NOTE: If you are installing from an existing NixOS installation, umask for root
account may cause incorrect permissions for `/mnt/etc`. Check those. This issue
has been fixed in recent NixOS.

**NOTE: If you are using LUKS inside LVM, you need to manually modify the
hardware configuration file `/mnt/etc/nixos/hardware-configuration.nix`. By
default, LVM is loaded after LUKS, so for those LUKS devices that are inside
LVM, you must set `preLVM = false`.**

### Installing

Install the system:

Something like could work on existing system but there's a bug in nixos-enter
that network doesn't work. See: https://github.com/NixOS/nixpkgs/issues/39665.

```
nixos-enter --root /mnt
yadm -Y /etc/nixos/.yadm alt
mkdir -p /run/user/0
nixos-install --root /
```

If this worked (or yadm used relative alt links), all the yadm-related `/mnt`
tricks should be unnecessary on an existing system. But instead use the
following:

```
nixos-install --no-root-passwd
```

If you have NixOS already installed and you want to use nixpkgs from that
installation:

```
nixos-install --no-root-passwd -I /nix/store/<SOME HASH HERE>/nixos/nixpkgs
```

To find out the hash, figure out where the symlinks are pointing recursively:

```
ls -l /nix/var/nix/profiles/per-user/root/channels
```

NOTE: The symlinks are pointing to absolute paths `/nix/...` but that existing
system is under `/mnt/nix/...` so the symlinks aren't actually working but must
be prepended with `/mnt`.

Finally, after running the installation, reboot to the new system:

```
reboot
```

After you have booted to the newly installed NixOS system, remove the hack
symlink:

```
rm /mnt
```

Modify the worktree path in `/etc/nixos/.yadm/repo.git/config`. Regenerate alt
symlinks.

```
yadm -Y /etc/nixos/.yadm alt
```

## Other useful stuff

### Encrypted USB sticks

These instructions help creating a USB stick so that it's encrypted but anyone
who can decrypt the stick, can have read&write permissions to all files and can
create new files. The stick works only on Linux though.

- TODO: Create the encrypted disk..

- Mount the disk.

- Go to the mounted directory:

  ```
  cd /run/media/username/SOME_STICK_NAME
  ```

- Make `users` the default group:

  ```
  chmod g+s .
  ```

- Set default permissions for new files and directoies:

  ```
  setfacl -R -d -m u::rwx .
  setfacl -R -d -m g::rwx .
  setfacl -R -d -m o::0 .
  ```

If you had created the encrypted stick before, you may already have something
on the stick. You can configure that content as follows:

- Change the group to `users`:

  ```
  chgrp -R users .
  ```

- Set the default group recursively (only for directories):

  ```
  find . -type d -exec chmod g+s {} \;
  ```

- Set permissions:

  ```
  chmod -R ug+rwX .
  ```
