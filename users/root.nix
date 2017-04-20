{
  imports = [
    ./root-password.nix
  ];

  users.extraUsers.root = {
    isNormalUser = false;
  };
}
