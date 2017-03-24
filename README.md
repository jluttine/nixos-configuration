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

If your hostname isn't included in the configuration file alternatives, symlinks aren't created properly. See Yadm manuals for more information.
