let

  passwords = import ./passwords;

  createUser = { username, id, realname }: { sudo }: {
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
  }

  {
    username = "meri";
    realname = "Meri Luttinen";
    id = 1001;
  }

]
