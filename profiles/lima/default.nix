{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.lima-vm;
in {
  imports = [
    ./lima-configuration.nix
    ./lima-init.nix
    ./lima-runtime.nix
  ]
  
  environment = {
    systemPackages = with pkgs; [
      rsync
    ];
  };
}
