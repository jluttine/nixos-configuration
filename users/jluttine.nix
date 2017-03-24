{
  imports = [
    ./jluttine-password.nix
  ];

  users.users.jluttine = {
    description = "Jaakko Luttinen";
    home = "/home/jluttine";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
