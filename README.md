# NixOS configurations

My personal NixOS configurations. Clone the repository:

```
git clone https://username@github.com/jluttine/nixos-configuration /etc/nixos
cd /etc/nixos
```

Decrypt some encrypted configuration:
```
yadm -Y /etc/nixos/.yadm decrypt
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

### Creating fully encrypted file system

```
DISK=/dev/sda
```


```
sgdisk --zap-all $DISK
```

```
fdisk $DISK
```

Create GPT partition table. If using BIOS (with GPT), create 1M partition of
type BIOS boot (e.g., partition id 4). Then, create partitions for boot (e.g.,
partition id 1 assumed below and 1GB) and (encrypted) root (partition id 2
assumed below). The BIOS boot partition won't be given any filesystem, it is
just for grub.


After fdisk, prepare an encrypted root file system:

```
cryptsetup -y -v luksFormat "$DISK"2
cryptsetup open "$DISK"2 cryptroot
mkfs.ext4 -L nixos-root /dev/mapper/cryptroot
mount -t ext4 /dev/mapper/cryptroot /mnt
```

Optionally, test that the encrypted file system works:

```
umount /mnt
cryptsetup close cryptroot
cryptsetup open "$DISK"2 cryptroot
mount -t ext4 /dev/mapper/cryptroot /mnt
```

Prepare boot partition:

```
mkfs.ext4 -L nixos-boot "$DISK"1
mkdir /mnt/boot
mount -t ext4 "$DISK"1 /mnt/boot
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
account may cause incorrect permissions for `/mnt/etc`. Check those.

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
