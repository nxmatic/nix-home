{ config, modulesPath, pkgs, lib, ... }:

let
    LIMA_CIDATA_MNT = "/mnt/lima-cidata";  # FIXME: hardcoded
    LIMA_CIDATA_DEV = "/dev/disk/by-label/cidata";  # FIXME: hardcoded

    self_path = "./.";
      
    script = ''
    set -eux
    exec &> >(tee -a /var/log/lima-init.log)
    echo "attempting to fetch configuration from LIMA user data..."
    export HOME=/root
    export PATH=${pkgs.lib.makeBinPath [ pkgs.gnused config.nix.package config.system.build.nixos-rebuild]}:$PATH
    export NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels

    if [ -f ${LIMA_CIDATA_MNT}/lima.env ]; then
        echo "storage exists";
    else
        echo "storage not exists";
        exit 2
    fi

    cp -f ${self_path}/*.nix /etc/nixos && \
       chmod 664 /etc/nixos/*.nix

    sed -i 's@imports = \[];@imports = \[ "/etc/nixos/lima-runtime.nix" ];@g' /etc/nixos/lima-init.nix

    nixos-rebuild switch
    nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq

    cp "${LIMA_CIDATA_MNT}"/meta-data /run/lima-ssh-ready
    cp "${LIMA_CIDATA_MNT}"/meta-data /run/lima-boot-done
    exit 0
    '';
in {
    imports = [];  # PLACE HOLDER #

    environment.systemPackages = with pkgs; [
      emacs-nox # optional 
      hostctl
    ];

    systemd.services.lima-init = {
      inherit script;
      description = "Reconfigure the system from lima-init userdata on startup";

      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      requires = [ "network.target" ];

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    fileSystems."${LIMA_CIDATA_MNT}" = {
        device = "${LIMA_CIDATA_DEV}";
        fsType = "auto";
        options = [ "ro" "mode=0700" "dmode=0700" "overriderockperm" "exec" "uid=0" ];
    };
}
