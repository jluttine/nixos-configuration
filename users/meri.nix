{
  imports = [
    ./meri-password.nix
  ];

  users.users.jluttine = {
    description = "Meri Luttinen";
    home = "/home/meri";
    isNormalUser = true;
    uid = 1001;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
