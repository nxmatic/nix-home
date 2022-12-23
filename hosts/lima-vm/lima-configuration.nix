{ config, modulesPath, pkgs, lib, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/headless.nix")
  ];

  # for future backward compatibility (nixos)
  system.stateVersion = "22.11";

  # system boot
  boot = {
    #kernelParams = [ "console=ttyS0" "boot.shell_on_fail" ];
    kernelParams = [ "console=ttyS0,115200" "console=tty0" ];
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

  # root session (ssh,getty)
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  users.users.root.password = "nixos";

  systemd = {
    services."serial-getty@ttyS0" = {
      enable = true;
      wantedBy = [ "getty.target" ]; # to start at boot
      serviceConfig.Restart = "always"; # restart when session is closed
    };
  };

  security = {
    sudo.wheelNeedsPassword = false;
  };

  # nix cli settings
  nix.settings = {
    experimental-features = [ 
      "nix-command" 
      "flakes"
    ];
  };

  # virtualisation
  virtualisation = {
    # graphics = false;
    # useNixStoreImage = true;
    # writableStore = true;

    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.dnsname.enable = true;
    };
  };

  # documentation
  documentation = {
    enable = true;
    doc.enable = true;
  };

}
