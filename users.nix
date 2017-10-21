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
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDr1XPwrOxo6FFqmxkhextUdS+z4Dcu7TAPiyddWcntFNFyZch0tvOb4pkXkzN+ZNLTjSsjHqm2amXWyLdcH5evm5PutuU/8YkPUaBEC0nFvlIqCJlYsXE6EqkZL9FFVxVQmi+cRqGbbcZTkfTBezwdZtOORgiMj2IU282TFl+PjI71dhwf1IibXWC6HRfCUhxOLfdoyZEqv6qWFd34d10U/JzaFOd8vajL2M72XhTzDi1vmGXBoN61Bo1CqqVw5O6y0YLbnDlOjVcg/AtWspW4v/62+PvtetBIXfZY2Y9V9OOBaX2zWgaaoUMQQDrbzlNya7nz3UO9IVH0KEDNYHFSNGdO8nY8AcystnUkUvR77AldFh0hjLxnbRGRiZcFQrdgeZgh3G+W0tas7IXo0QgyTQWZ3s+fvKZ3/7YvBrmGgm68kswNBYM5s70Lrq5YUV5Rkh5gkQyDQbB21wQXhxLE34IHmppq7upSjHZqXCfCyfD9BJNYrLuoUnNAb0EU24Mfp+DsvNAja4Es7Fu8A2zA2OtfDq3/NJO9UJSEzRHw4VTv4lcbb4QuWcwEEiNsSKG3SZ6r59tkTyvi16irk9R3rOcYBSAGXpbhum2vrNboousMxp8/5ugHmeRiTk4rj5Kh1owP3djuYa7LbL813PbhLaPGgV3oW6N6NSMaXRiQew== tablet key"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZABRP9GBCapo74u3hFx9Fjro8GpV0IKkfkcgflk2mE9zegWUfEsgUK2lT09ALTMGeZhNQaw21JhLwt6AFKiON2gCt7iXK+mH2KN4at4GKkAqV4nEavBFQe9eh0Hw0mYDZwJJ1EnstPGxXnFWJlwikB+G8W+14tYTpO/G+Y2nQMk/lweQz+hwCWu84mWZ5P01oc4zhOcpDxbUT34rgeehNs4uOM1BTS9Ol34PJdYh5wipruRaIrEdhVl1ES7R9wo04sBcoeMSaiFuS6aaJ53V+W39eek32MVtV3GLYgvhiuHUFwfeSVnmO8/i3CpqMfKHc/GC05Xj2CW2R7v/GG4RhuCaOvLrWSZBDDLBFFK1EYvRFV1KHbTgwzdHT2AId4N/+z9944yCaOTQBXiSaUaDEdEiClqafyaQTI2YpsDZyrSyy8OVM8Accx6jh4+DCXjT8YzGDiv5Vjuo1qd+MyXbtFTsqtYfnQqAk8EEhojuDPAr7okLPrH1o70gHPUkXtiAcSWfE0Al/fYASG6l7HPvsFj3+aKcPoSNDF4jPT1c6Hb77i3yVkzDcZE8YH7OmPzpuctCwhPv2EFmYzCAkhKk2piaD8O7XDU3ovzYd/Q5RHvO7QB4bKFBPGdqpPZCDaVLxFUyczFdcjn1bBH5+43MhjGU7FrY7XybTLn4iT4vviQ== Taskuloinen"
    ];
  }

  {
    username = "meri";
    realname = "Meri Luttinen";
    id = 1001;
    keys = [ ];
  }

]
