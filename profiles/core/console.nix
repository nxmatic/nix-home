{ config, modulesPath, pkgs, lib, ... }:
{
  boot = {
    kernelParams = [
      "verbose=1"
      "root=/dev/vda2"
      "console=ttyS0,115200"
      "console=tty0"
      "boot.trace=1"
      "boot.shell_on_fail=1"
      "boot.debug1=1"          # stop right away
#     "boot.debug1device=1"    # stop after loading modules and creating device nodes
#     "boot.debug1mounts=1"    # stop after mounting file systems
    ];
  };

  # root session (ssh,getty)
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

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

  networking = {
    networkmanager = {
      enable = true;
    };
  };

}
