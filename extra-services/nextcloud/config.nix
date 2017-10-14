{lib, config, ...}:
#name, instanceConfig, ...}:
let

  #cfg = instanceConfig;

  # socket = instanceConfig.socket {
  #   inherit lib config name instanceConfig;
  #   #socketConfig = instanceConfig.socketConfig;
  # };

  # server = instanceConfig.server {
  #   inherit lib config name instanceConfig;
  #   #serverConfig = instanceConfig.serverConfig;
  # };

  # socketArgs = {
  #   inherit globalConfig;
  #   serverUser = cfg.server.user;
  #   serverGroup = cfg.server.group;
  # };

  # serverArgs = {
  #   inherit globalConfig;
  #   socketPath = cfg.socket.path;
  #   socketType = cfg.socket.type;
  #   nextcloudPackage = cfg.package;
  # };

in
{

  imports = [
    ./vhosts/nginx.nix
    ./sockets/fpm.nix
  ];

  options = with lib; {
    # socket = mkOption {type = types.unspecified;};
    # server = mkOption {type = types.unspecified;};
    # socketConfig = socket.options;
    # serverConfig = server.options;
  };

  config = {

    # services.phpfpm = socket.phpfpm or {};
    # services.nginx = server.nginx or {};

    # services.phpfpm = (
    #   (socket.phpfpm or ({...}: {}))
    #   socketArgs
    # );

    # services.nginx = (
    #   (server.nginx or ({...}: {}))
    #   serverArgs
    # );

    # services.nginx = (
    #   (cfg.server.nginx serverArgs)
    #   or {}
    # );

  };

}
