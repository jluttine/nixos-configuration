{
  imports = [
    ./meri-password.nix
  ];

  users.extraGroups.meri.gid = 1001;

  users.extraUsers.meri = {
    description = "Meri Luttinen";
    home = "/home/meri";
    isNormalUser = true;
    uid = 1001;
    extraGroups = [ "meri" "wheel" "networkmanager" ];
  };
}
