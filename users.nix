let

  passwords = import ./passwords;

  createUser = { username, id, realname, keys }: { groups }: {
    username = username;
    group.gid = id;
    user = {
      description = realname;
      uid = id;
      group = username;
      extraGroups = [ "networkmanager" "users" ] ++ groups;
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
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCe8SW3zjsgmXifzy0ZR6yUGiGGkxNAWKMY/z7FlOUqie4Ql2aOWghUkt1BYJNcfZamvSd9RUkO/R+Jvw45NUqwKh31Vz+9GBBktmhXVDG28Wf0RMLDaqV14KY0He8wYdflIQ18Q/NtyHcsO5qBYsFEWV4nuxcEHvkdN6cL9NsiEFsnRfLuHeIBnny/x+G7o+NUjxtbGKZSfAIKPaQZ8iiNP0scaJraT/iC5ehdTMGaaKIInuqHkn1tz8DmA/naaAoFV8A5RT54xApuGlboP3p2XhKA2BMH2WXJE+aEUbdt/GdcrJjQYOVaJTCjxdXaRjyCWTiRJYxXPghlnOrviyJ5 taskuloinen"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDr1XPwrOxo6FFqmxkhextUdS+z4Dcu7TAPiyddWcntFNFyZch0tvOb4pkXkzN+ZNLTjSsjHqm2amXWyLdcH5evm5PutuU/8YkPUaBEC0nFvlIqCJlYsXE6EqkZL9FFVxVQmi+cRqGbbcZTkfTBezwdZtOORgiMj2IU282TFl+PjI71dhwf1IibXWC6HRfCUhxOLfdoyZEqv6qWFd34d10U/JzaFOd8vajL2M72XhTzDi1vmGXBoN61Bo1CqqVw5O6y0YLbnDlOjVcg/AtWspW4v/62+PvtetBIXfZY2Y9V9OOBaX2zWgaaoUMQQDrbzlNya7nz3UO9IVH0KEDNYHFSNGdO8nY8AcystnUkUvR77AldFh0hjLxnbRGRiZcFQrdgeZgh3G+W0tas7IXo0QgyTQWZ3s+fvKZ3/7YvBrmGgm68kswNBYM5s70Lrq5YUV5Rkh5gkQyDQbB21wQXhxLE34IHmppq7upSjHZqXCfCyfD9BJNYrLuoUnNAb0EU24Mfp+DsvNAja4Es7Fu8A2zA2OtfDq3/NJO9UJSEzRHw4VTv4lcbb4QuWcwEEiNsSKG3SZ6r59tkTyvi16irk9R3rOcYBSAGXpbhum2vrNboousMxp8/5ugHmeRiTk4rj5Kh1owP3djuYa7LbL813PbhLaPGgV3oW6N6NSMaXRiQew== tablet key"
    ];
  }

  {
    username = "meri";
    realname = "Meri Luttinen";
    id = 1001;
    keys = [ ];
  }

]
