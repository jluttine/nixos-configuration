{
  imports = [
    ./meri-password.nix
  ];

  users.extraGroups.meri.gid = 1001;

  users.extraUsers.meri = {
    description = "Meri Luttinen";
    home = "/home/meri";
    group = "meri";
    isNormalUser = true;
    uid = 1001;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
