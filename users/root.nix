{
  imports = [
    ./root-password.nix
  ];

  users.users.root = {
    isNormalUser = false;
  };
}
