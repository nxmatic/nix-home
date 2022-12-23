{ config, pkgs, lib, ... }:
{
  imports = [
    ./home.nix
  ];

  users = {
    mutableUsers = false;

    users = with pkgs; pkgs.lib.setAttrByPath [ config.lima-vm.user.name ] {
      # Indicates whether this is an account for a “real” user.
      # This automatically sets group to users, createHome to true,
      # home to /home/username, useDefaultShell to true, and isSystemUser to false.
      isNormalUser = true;
      description = lib.mkForce config.lima-vm.user.description;
      extraGroups = [ "wheel" "docker" "input" "networkmanager" ];
      initialHashedPassword = if config.lima-vm.user.password != null then config.lima-vm.user.password else "";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = if config.lima-vm.user.publicKeys != null then config.lima-vm.user.publicKeys else [ ];
    };
  };
}
