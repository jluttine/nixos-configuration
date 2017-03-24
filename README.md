# NixOS configurations

My personal NixOS configurations. Clone the repository:

```
git clone https://username@github.com/jluttine/nixos-configuration /etc/nixos
```

Symlink the desired configuration:

```
cd /etc/nixos
ln -s some.nix configuration.nix
```

If needed, first create a new configuration and modify it to your needs:

```
cp template.nix givename.nix
vim givename.nix
```
