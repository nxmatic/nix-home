{ config, modulesPath, pkgs, lib, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/headless.nix")
    ./lima-init.nix
    ./lima-init-podman.nix
  ];

  # for future backward compatibility (nixos)
  system.stateVersion = "23.05";

  # virtualisation
  #virtualisation.graphics = false;
  #virtualisation.useNixStoreImage = true;
  #virtualisation.writableStore = true;

  # ssh
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  users.users.root.password = "nixos";

  security = {
    sudo.wheelNeedsPassword = false;
  };

  # system boot
  boot = {
    kernelParams = [ "console=ttyS0" "boot.shell_on_fail" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      timeout = pkgs.lib.mkForce 5;
    };
  };

  # file system mounts
  fileSystems."/boot" = {
    device = "/dev/vda1";  # /dev/disk/by-label/ESP
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
    options = [ "noatime" "nodiratime" "discard" ];
  };

  # nix cli settings
  nix.settings = {
    experimental-features = [ 
      "nix-command" 
      "flakes"
    ];
  };

  # documentation
  documentation = {
    enable = true;
    doc.enable = true;
  };

}
