{
  config,
  modulesPath,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.lima-vm;
in {
  imports = [
    (modulesPath + "/profiles/headless.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./lima-configuration.nix
    ./lima-init.nix
  ] ++ lib.optional ( builtins.pathExists /mnt/lima-cidata ) ./lima-runtime.nix;
  
  environment = {
    systemPackages = with pkgs; [
      rsync
    ];
  };
}
