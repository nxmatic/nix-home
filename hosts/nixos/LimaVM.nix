{suites, profiles, modulesPath, pkgs, ...}: {
  imports = suites.lima
            ++
            [
              (modulesPath + "/profiles/headless.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              # profiles.home
              # profiles.lima.lima-configuration
              # profiles.lima.lima-init
            ]
  ;

  # system boot
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
 };

  # file system mounts
  fileSystems = {
    # "/boot" = {
    #   device = "/dev/disk/by-label/ESP";  # /dev/vda1
    #   fsType = "vfat";
    # };
   "/" = {
     device = "/dev/disk/by-label/nixos";
     autoResize = true;
     fsType = "ext4";
     options = [ "noatime" "nodiratime" "discard" ];
   };
  };

}
