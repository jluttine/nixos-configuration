let

  passwords = import ./passwords;

  createUser = { username, id, realname, keys }: { sudo }: {
    username = username;
    group.gid = id;
    user = {
      description = realname;
      uid = id;
      group = username;
      extraGroups = [ "networkmanager" "users" ] ++ (
        if sudo then [ "wheel" ] else []
      );
      home = "/home/${username}";
      isNormalUser = true;
      hashedPassword = builtins.getAttr username passwords;
      openssh.authorizedKeys.keys = keys;
    };
  };

  createUsers = xs: builtins.listToAttrs (
    builtins.map
    (
      x: {
        name = x.username;
        value = (createUser x);
      }
    )
    xs
  );

in createUsers [

  {
    username = "jluttine";
    realname = "Jaakko Luttinen";
    id = 1000;
    keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0YI4Wv5itxAEIgJTzQRv30OTHxQOosglGIIjijfVsHb/S5+Dy/ay3loOmOE9995AYwpBnN57Emr4HNCqFaizJ+repzmV191J5dAnqxVpKdD2u/mZ2aDh38tlfh84Z2SXpBh4EcJG2Ag6j5XYWBinlcsK6nUM8GundmxNtcKPy9cbSqj/+V1/YHz7DRv2iXIQl2hsLTaFdpQ/mPmzx7Govovlyp8JTkYzr8E7qQjbpuBA276HDX5L2wLWf37zIfNGc32ZMiwss1gCbopD3hBsELJrAA4LoQ+uM4XZSWHc+skNMmiENsayZfgrCI6EylcR1ixB1aQ9NRElgIWdIUc8h jluttine@leevi"
    ];
  }

  {
    username = "meri";
    realname = "Meri Luttinen";
    id = 1001;
    keys = [ ];
  }

]
