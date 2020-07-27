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

### Creating the installer USB stick

Download the installer ISO image from [nixos.org](https://nixos.org). Plug a USB
stick to your computer and find its device name with:

```
lsblk
```

If the USB stick is mounted, unmount all the mounted partitions as follows but
replace `/dev/sdxN` with the device name (e.g., `/dev/sdb1`):

```
umount /dev/sdxN
```

So, for instance, it could be:

```
umount /dev/sdb1
umount /dev/sdb2
```

Write the ISO image to the USB stick as follows but replace `path/to/nixos.iso`
with the ISO image file path and `/dev/sdx` with the USB stick device path
(`lsblk` can be used to show that):

```
sudo dd bs=4M if=path/to/nixos.iso of=/dev/sdx status=progress oflag=sync
```

Of course, there are many alternative USB disk writing tools that provide
graphical user interface.

After the writing has completed, plug the USB stick to the computer you want
NixOS to be installed to and boot it to the NixOS installer.

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
fdisk. Run `sudo fdisk /dev/some-device` for each device you want to partition.
I created GPT partition tables for them. Below are my somewhat cryptic and
compact notes on how I partitioned my two machines.

On a laptop with only one disk, I created an unencrypted partition for `/boot`
and an encrypted partition for `/`:

- 250 GB SSD
  - partition 4, type 4 = BIOS boot, size = 1M
  - partition 1, size = 1G, ext4 nixos-boot, `/boot`
  - partition 2, size = 100%, LUKS luks-nixos-root, ext4 nixos-root, `/`

On a server with one large disk:

- 2 TB SSD
  - partition 4, type 4 = BIOS boot, size = 1M
  - partition 1, size = 1G, ext4 nixos-boot, `/boot`
  - partition 2, type 31 = LVM, size = 500G, VG vg-nixos-var
    - LV lv-nixos-var, size = 450G, LUKS luks-nixos-var, ext4 nixos-var, `/var`
    - remaining 50G will be reserved for snapshots
  - partition 3, size = 100%, LUKS luks-nixos-root, ext4 nixos-root, `/`

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

(When running `mkfs.ext4` command, I once got a warning that complained about
existing `atari` partition table. Apparently, some random data in the LUKS
device was interpreted incorrectly, and it got fixed by running `wipefs -a
/dev/mapper/put-luks-label-here`.)

Mount each file system to its place under `/mnt`. For instance, I mounted
`nixos-root` under `/mnt` and `nixos-boot` under `/mnt/boot`.


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

Check that the grub device is set correctly. In this repository, it is set in
`local-configuration.nix` file. The value should point to one of the disks (not
partitions).

Also, if in `local-configuration.nix`, `nixpkgs` is set and it points to a local
path like `/etc/nixpkgs`, clone nixpkgs repository under `/mnt/etc/nixpkgs`,
checkout the desired branch/commit and create a symlink `ln -s /mnt/etc/nixpkgs
/etc/nixpkgs`.

### Installing

#### From live USB stick

If installing from a live USB stick, just run:

```
nixos-install --no-root-passwd
```

Or if using local checkout of `nixpkgs`:

```
nixos-install --no-root-passwd -I /mnt/etc/nixpkgs
```

#### From existing installation

If installing from an existing running NixOS installation, something like could
work on existing system but there's a bug in nixos-enter that network doesn't
work. See: https://github.com/NixOS/nixpkgs/issues/39665.

```
nixos-enter --root /mnt
yadm -Y /etc/nixos/.yadm alt
mkdir -p /run/user/0
nixos-install --root /
```

But instead use the following:

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


### Booting to the new system

Finally, after running the installation, reboot to the new system:

```
reboot
```

Modify the worktree path in `/etc/nixos/.yadm/repo.git/config`.

Set permissions for `/etc/nixos` (and `/etc/nixpkgs` if used):

```
TODO
```


### Backing up the system

Different parts of the system are backed up differently. Here's an overview how
I've set it up:

- System configuration -> NixOS configuration files in GitHub
- Dotfiles in home directory -> GitHub
- Important files under home directory -> home server by using syncthing
- Home server stateful `/var` directory -> remote encrypted disk snapshot

(Note that the syncthing on the home server stores files under `/var` so they'll
get backed up remotely.)

So, for the server, the setup is such that everything that needs to be backed up
is under `/var` which is inside an encrypted logical volume `lv-nixos-var`.
Snapshots of this logical volume are stored remotely so that even if the house
burned down, there's an encrypted remote backup that can be used to restore
`/var` exactly as it was.

In short, the system is backed up by taking a snapshot and syncing that to a
remote disk image file:

```
modprobe dm-snapshot    # if needed
lvcreate -l 100%FREE -s -n lv-nixos-var-snapshot /dev/vg-nixos-var/lv-nixos-var
diskrsync --no-compress /dev/vg-nixos-var/lv-nixos-var-snapshot user@host:/path/to/disk.img
```


### Restoring the system

If something breaks or hardware is changed, one needs to copy the existing/old
system to the new hardware. Here's a rough overview of the steps:

1. Create disk partitions on the new hardware as desired (see above).
2. Copy important stateful content from the old setup to the new one.
  - Home directory content can be copied from disk to another with:
    ```
    rsync -a --delete --info=progress2 --exclude="/lost+found" /path/to/old/ /path/to/new/
    ```
    Or if it was lost, it can be restored with syncthing from the home server.
  - Dotfiles can be restored from GitHub.
  - Home server `/var` logical volume can be cloned from a local disk or remote
    disk image.
3. Copy NixOS configuration (see above).
4. Install NixOS (see above).

This section explains how restore `/var` logical volume of the home server. One
may want to restore or clone the encrypted logical volume if the disk needs to
be updated or if it broke. In the first case, one can attach the old and the new
disk to a same machine and just clone the logical volume. In the second case,
use the (remote) disk image that was backed up and clone the logical volume
based on that. In either case, make sure the new logical volume has exactly the
same size (`lsblk -b`). If needed, it can be resized after cloning.

#### Cloning a local logical volume

If restoring from a local disk on a same machine, having the same VG and LV
names on two disks (the old and the new) causes problems. So, first detach the
new disk and boot with a live USB stick. Rename the volume group on the old
disk, for instance:

```
vgrename vg-nixos-var vg-nixos-var-old
```

(It is possible to rename while they both are attached by checking the UID with
`vgdisplay` and then using `vgrename <UID> vg-nixos-var-old`. But the above
method might be less error-prone and safer.)

Now, reboot to the live USB stick with both the new and the old disks attached.
First, make sure the logical volumes are active (`lvscan`) but not mounted
(`lsblk`). Especially the disk with a snapshot might require special attention:

```
modprobe dm-snapshot
vgchange -a y vg-nixos-var-old
```

Finally, the actual cloning. Here's an example but be sure to set the input and
output names correctly:

```
dd if=/dev/vg-nixos-var-old/lv-nixos-var of=/dev/vg-nixos-var/lv-nixos-var bs=64M status=progress oflag=sync
```

#### Cloning a (remote) disk image

(If it's a remote disk image, perhaps mount the directory first with `sshfs`.)

Cloning example:

```
dd if=/path/to/diskimage.img of=/dev/vg-nixos-var/lv-nixos-var bs=64M status=progress oflag=sync
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
