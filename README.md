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

```
nixos-install
```

Reboot to the new system:

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
