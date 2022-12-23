{ config, modulesPath, pkgs, lib, ... }:

{
  imports = [
    ./lima-configuration.nix
    ./lima-init.nix
  ];
}
