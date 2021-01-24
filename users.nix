{ lib, config, pkgs, ... }:

let

  passwords = import ./passwords;

  users = {

    jluttine = {
      realname = "Jaakko Luttinen";
      id = 1000;
      keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0YI4Wv5itxAEIgJTzQRv30OTHxQOosglGIIjijfVsHb/S5+Dy/ay3loOmOE9995AYwpBnN57Emr4HNCqFaizJ+repzmV191J5dAnqxVpKdD2u/mZ2aDh38tlfh84Z2SXpBh4EcJG2Ag6j5XYWBinlcsK6nUM8GundmxNtcKPy9cbSqj/+V1/YHz7DRv2iXIQl2hsLTaFdpQ/mPmzx7Govovlyp8JTkYzr8E7qQjbpuBA276HDX5L2wLWf37zIfNGc32ZMiwss1gCbopD3hBsELJrAA4LoQ+uM4XZSWHc+skNMmiENsayZfgrCI6EylcR1ixB1aQ9NRElgIWdIUc8h jluttine@leevi"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDr1XPwrOxo6FFqmxkhextUdS+z4Dcu7TAPiyddWcntFNFyZch0tvOb4pkXkzN+ZNLTjSsjHqm2amXWyLdcH5evm5PutuU/8YkPUaBEC0nFvlIqCJlYsXE6EqkZL9FFVxVQmi+cRqGbbcZTkfTBezwdZtOORgiMj2IU282TFl+PjI71dhwf1IibXWC6HRfCUhxOLfdoyZEqv6qWFd34d10U/JzaFOd8vajL2M72XhTzDi1vmGXBoN61Bo1CqqVw5O6y0YLbnDlOjVcg/AtWspW4v/62+PvtetBIXfZY2Y9V9OOBaX2zWgaaoUMQQDrbzlNya7nz3UO9IVH0KEDNYHFSNGdO8nY8AcystnUkUvR77AldFh0hjLxnbRGRiZcFQrdgeZgh3G+W0tas7IXo0QgyTQWZ3s+fvKZ3/7YvBrmGgm68kswNBYM5s70Lrq5YUV5Rkh5gkQyDQbB21wQXhxLE34IHmppq7upSjHZqXCfCyfD9BJNYrLuoUnNAb0EU24Mfp+DsvNAja4Es7Fu8A2zA2OtfDq3/NJO9UJSEzRHw4VTv4lcbb4QuWcwEEiNsSKG3SZ6r59tkTyvi16irk9R3rOcYBSAGXpbhum2vrNboousMxp8/5ugHmeRiTk4rj5Kh1owP3djuYa7LbL813PbhLaPGgV3oW6N6NSMaXRiQew== tablet key"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiiguRZKRVZ47YVY0Gg0Z2lfaRkd61qfA2wX2gwkSY73pzSdWgylOZA4vhiUKctlpUsAUcphYVgpBmBAWhCon7QRVBodTNNf4FjHBYCu8pZ8/koS8vpVfEU64UBHSTSmkFRbtsbVrb2xOtEk21ygsxWuMiDkr8osIfgbT8DGQqLuzQmrWdNCL1vyAB+MfwwNOMhb4SPwLVf6aExFynhZEsww8POvobLgK9GDqr7VVz0uxw+yP25FzcqtuoQ2gqEl6ko+fEwa00e/OAzH1V11oBxlTGxNTcav5ggg4DCy3er+uV4WXJL/kvpZAOaqCxIC9e5sUSY9oxqyNxzjQvM9gaIHDpNOp0qOKsv0XdiyqW+vlpR4WNsJ2FhQY+8BhQom2NQ6/nHiirlNaeo6ksjB3nmHoiPo9ZbW+lbdrSu4gd3gSQeR8jhXL9duq4laE/tMXdWs2NFcATr3k+rTR1ZTKHSVgp0fWfPdhJlVQRRdgZjw2VRi+poYMKg5w5NUur4rP1sjq80sLz9n667XAg0FBshnqWxDe/AXJerEAHNVjVH87lwWhDI15DslXBSDeX6Waqdv0cFuNto/RxlccAyolXoSOm7vGhjU9VEXVeVYb5p8s+Wm+M2C807plDLPwnKXfLSMwB1jHQzTMtBRoWTtu8UW0XxKlBnc1o52FIOia6XQ== Taskuloinen"
      ];
    };

    meri = {
      username = "meri";
      realname = "Meri Luttinen";
      id = 1001;
      keys = [ ];
    };
  };

in {

  options = {
    users.predefinedUsers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.string);
    };
  };

  config = {

    # Immutable users and groups
    users.mutableUsers = false;

    users.users = builtins.mapAttrs (username: groups: with users."${username}"; {
      description = realname;
      uid = id;
      extraGroups = [ "networkmanager" "video" ] ++ groups;
      isNormalUser = true;
      hashedPassword = builtins.getAttr username passwords;
      openssh.authorizedKeys.keys = keys;
    }) config.users.predefinedUsers;
  };
}
