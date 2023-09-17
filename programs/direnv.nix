# { lib, config, pkgs, ... }: {
#   options = {
#     programs.direnv = {
#       enable = lib.mkEnableOption "nix-direnv";
#     };
#   };

#   config = lib.mkIf config.programs.direnv.enable {
#     environment.systemPackages = with pkgs; [ direnv nix-direnv ];
#     # nix options for derivations to persist garbage collection
#     nix.settings = {
#       keep-outputs = true;
#       keep-derivations = true;
#     };
#     environment.pathsToLink = [
#       "/share/nix-direnv"
#     ];
#     # if you also want support for flakes
#     nixpkgs.overlays = [
#       (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; } )
#     ];
#   };
# }
