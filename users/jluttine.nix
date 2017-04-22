{
  imports = [
    ./jluttine-password.nix
  ];

  users.extraGroups.jluttine.gid = 1000;

  users.extraUsers.jluttine = {
    description = "Jaakko Luttinen";
    home = "/home/jluttine";
    group = "jluttine";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
