{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}: let
  cfg = config.lima-vm;

  LIMA_CIDATA_MNT = cfg.cidata-mnt;

  # Nix can only natively “import” TOML, JSON and Nix. Nix lacks YAML support.
  # This has some drawbacks, mainly that yj needs to be available at evaluation time
  # (so if it’s not cached you are looking at building it) and evaluation will block on the
  # build of the converted JSON as evaluation is single-threaded.
  fromYAML = yaml: builtins.fromJSON (
    builtins.readFile (
      pkgs.runCommandNoCC "from-yaml"
        {
          inherit yaml;
          allowSubstitutes = false;
          preferLocalBuild = true;
        }
        ''
              ${pkgs.remarshal}/bin/remarshal  \
                -if yaml \
                -i <(echo "$yaml") \
                -of json \
                -o $out
            ''
    )
  );
  readYAML = path: fromYAML (builtins.readFile path);

  userData = readYAML "${LIMA_CIDATA_MNT}/user-data";
  envsContent = lib.forEach (lib.splitString "\n" (builtins.readFile "${LIMA_CIDATA_MNT}/lima.env")) (x: (lib.splitString "=" x));
  envFromContentList = envName: lib.forEach (builtins.filter (x: (builtins.match ("^"+envName+"$") (builtins.elemAt x 0)) != null) envsContent) (x: builtins.elemAt x 1);
  envFromContent = envName: lib.last(envFromContentList envName);

  LIMA_CIDATA_NAME = envFromContent "LIMA_CIDATA_NAME";
  LIMA_CIDATA_SLIRP_GATEWAY = envFromContent "LIMA_CIDATA_SLIRP_GATEWAY";
  LIMA_CIDATA_UDP_DNS_LOCAL_PORT = envFromContent "LIMA_CIDATA_UDP_DNS_LOCAL_PORT";
  LIMA_CIDATA_TCP_DNS_LOCAL_PORT = envFromContent "LIMA_CIDATA_TCP_DNS_LOCAL_PORT";
  LIMA_CIDATA_SLIRP_DNS = envFromContent "LIMA_CIDATA_SLIRP_DNS";
  LIMA_CIDATA_USER = envFromContent "LIMA_CIDATA_USER";
  LIMA_CIDATA_UID = lib.toInt (envFromContent "LIMA_CIDATA_UID");
  LIMA_CIDATA_MOUNTTYPE = envFromContent "LIMA_CIDATA_MOUNTTYPE";
  LIMA_CIDATA_MOUNTS = lib.toInt (envFromContent "LIMA_CIDATA_MOUNTS");

  LIMA_MOUNTPOINTS = envFromContentList "LIMA_CIDATA_MOUNTS_[0-9]+_MOUNTPOINT";
  LIMA_SSH_KEYS = (lib.elemAt (userData . "users") 0) . "ssh-authorized-keys";

  script_mounts = if LIMA_CIDATA_MOUNTTYPE != "9p" then (lib.concatStringsSep "\n" (lib.forEach LIMA_MOUNTPOINTS (mountpoint:
    ''
        mkdir -p "${mountpoint}";
        chown "${toString LIMA_CIDATA_UID}:$gid" "${mountpoint}";
        ''
  ))) else "";

  fileSystemsMount = (lib.zipAttrsWith (name: values: (lib.elemAt values 0)) (lib.forEach (userData . "mounts") (row:
    {
      ${(lib.elemAt row 1)} = {
        device = (lib.elemAt row 0);
        fsType = (lib.elemAt row 2);
        options = (lib.splitString "," (lib.elemAt row 3));
      };
    }
  )));

  script = ''
    set -eux
    exec &> >(tee -a /var/log/lima-runtime.log)
    echo "fix symlink for /bin/bash"
    ln -fs /run/current-system/sw/bin/bash /bin/bash

    echo "make mount points"
    gid=$(id -g "${LIMA_CIDATA_USER}")
    ${script_mounts}

    exit 0
    '';
in {
  networking = {
    extraHosts =
      ''
      ${LIMA_CIDATA_SLIRP_GATEWAY} host.lima.internal
      127.0.0.1 ${LIMA_CIDATA_NAME}
      '';
  };

  systemd = {

    services = {

      lima-runtime = {
        inherit script;
        description = "Reconfigure the system from lima-runtime userdata on startup";
        
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        
        restartIfChanged = false;
        unitConfig.X-StopOnRemoval = false;
        
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      lima-guestagent =  {
        enable = true;
        description = "Forward ports to the lima-hostagent";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ;
        serviceConfig = {
          Type = "simple";
          ExecStart = "${/. + "${LIMA_CIDATA_MNT}/lima-guestagent"} daemon";
          Restart = "on-failure";
        };
      };

    };

  };

  boot = {
    kernelModules = [ "tcp_bbr" ];

    kernel.sysctl = {
      "kernel.unprivileged_userns_clone" = 1;
      "net.ipv4.ping_group_range" = "0 2147483647";
      "net.ipv4.ip_unprivileged_port_start" = 0;
      "net.ipv4.tcp_min_snd_mss" = 536;
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  users.users."${LIMA_CIDATA_USER}" = {
    uid = LIMA_CIDATA_UID;
    home = "/home/${LIMA_CIDATA_USER}.linux";
    group = "users";
    shell = "/bin/bash";
    isSystemUser = true;
    extraGroups = [ "wheel" ];
    createHome = true;
    openssh.authorizedKeys.keys = LIMA_SSH_KEYS;
  };

  fileSystems = fileSystemsMount;

  programs.fuse = if LIMA_CIDATA_MOUNTTYPE == "reverse-sshfs" then { userAllowOther = true; } else { };

  environment.etc = {
    environment.source = "${LIMA_CIDATA_MNT}/etc_environment";  # FIXME: better handle?
  };

  networking.nat = {
    enable = true;
    extraCommands = ''
            iptables -t nat -A nixos-nat-out -d ${LIMA_CIDATA_SLIRP_DNS} -p udp -m udp --dport 53 -j DNAT --to-destination ${LIMA_CIDATA_SLIRP_GATEWAY}:${LIMA_CIDATA_UDP_DNS_LOCAL_PORT}
            iptables -t nat -A nixos-nat-pre -d ${LIMA_CIDATA_SLIRP_DNS} -p udp -m udp --dport 53 -j DNAT --to-destination ${LIMA_CIDATA_SLIRP_GATEWAY}:${LIMA_CIDATA_UDP_DNS_LOCAL_PORT}

            iptables -t nat -A nixos-nat-out -d ${LIMA_CIDATA_SLIRP_DNS} -p tcp -m tcp --dport 53 -j DNAT --to-destination ${LIMA_CIDATA_SLIRP_GATEWAY}:${LIMA_CIDATA_TCP_DNS_LOCAL_PORT}
            iptables -t nat -A nixos-nat-pre -d ${LIMA_CIDATA_SLIRP_DNS} -p tcp -m tcp --dport 53 -j DNAT --to-destination ${LIMA_CIDATA_SLIRP_GATEWAY}:${LIMA_CIDATA_TCP_DNS_LOCAL_PORT}
        '';
  };

}
