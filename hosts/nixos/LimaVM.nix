{suites, profiles, modulesPath, pkgs, ...}: {
  imports = suites.lima
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
